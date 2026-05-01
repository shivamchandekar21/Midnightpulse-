import * as functions from "firebase-functions/v1";
import * as https from "https";

// -------------------------------------------------------------------
// createRazorpayOrder — Cloud Function (HTTPS Callable)
//
// Creates a Razorpay order using the Razorpay REST API directly
// (no external SDK dependency needed).
//
// Store your keys via Firebase env config:
//   firebase functions:config:set razorpay.key_id="rzp_test_xxx"
//   firebase functions:config:set razorpay.key_secret="yyy"
//
// Or via environment variables: RAZORPAY_KEY_ID, RAZORPAY_KEY_SECRET
// -------------------------------------------------------------------

function razorpayRequest(
  keyId: string,
  keySecret: string,
  body: Record<string, unknown>,
): Promise<Record<string, unknown>> {
  return new Promise((resolve, reject) => {
    const postData = JSON.stringify(body);
    const auth = Buffer.from(`${keyId}:${keySecret}`).toString("base64");

    const options: https.RequestOptions = {
      hostname: "api.razorpay.com",
      port: 443,
      path: "/v1/orders",
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Content-Length": Buffer.byteLength(postData),
        "Authorization": `Basic ${auth}`,
      },
    };

    const req = https.request(options, (res) => {
      let data = "";
      res.on("data", (chunk) => (data += chunk));
      res.on("end", () => {
        try {
          const parsed = JSON.parse(data) as Record<string, unknown>;
          if (res.statusCode && res.statusCode >= 200 && res.statusCode < 300) {
            resolve(parsed);
          } else {
            reject(new Error(
              (parsed.error as Record<string, string>)?.description ??
              `Razorpay API error (HTTP ${res.statusCode})`,
            ));
          }
        } catch {
          reject(new Error(`Invalid JSON response from Razorpay: ${data}`));
        }
      });
    });

    req.on("error", reject);
    req.write(postData);
    req.end();
  });
}

export const createRazorpayOrder = functions.https.onCall(async (request) => {
  // Require authentication
  if (!request.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "You must be signed in to create an order.",
    );
  }

  const data = request.data;
  const amount = Number(data?.amount ?? 0);
  const currency = String(data?.currency ?? "INR");
  const receipt = String(data?.receipt ?? "");
  const notes = (data?.notes as Record<string, string>) ?? {};

  if (!amount || amount <= 0) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "amount must be a positive integer in paise",
    );
  }

  if (!receipt) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "receipt is required",
    );
  }

  // Read Razorpay credentials
  const keyId = process.env.RAZORPAY_KEY_ID ?? functions.config()?.razorpay?.key_id ?? "";
  const keySecret = process.env.RAZORPAY_KEY_SECRET ?? functions.config()?.razorpay?.key_secret ?? "";

  // If keys are not configured, return a stub order for dev/testing
  if (!keyId || !keySecret) {
    functions.logger.warn(
      "Razorpay keys not configured — returning stub order for development.",
    );
    return {
      orderId: `order_stub_${Date.now()}`,
      amount,
      currency,
    };
  }

  try {
    const order = await razorpayRequest(keyId, keySecret, {
      amount,
      currency,
      receipt,
      notes,
    });

    return {
      orderId: order.id as string,
      amount: order.amount as number,
      currency: order.currency as string,
    };
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : "Unknown error";
    functions.logger.error("Razorpay order creation failed", err);
    throw new functions.https.HttpsError(
      "internal",
      `Failed to create Razorpay order: ${message}`,
    );
  }
});
