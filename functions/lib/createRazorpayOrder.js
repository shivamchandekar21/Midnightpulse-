"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.createRazorpayOrder = void 0;
const functions = __importStar(require("firebase-functions/v1"));
const https = __importStar(require("https"));
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
function razorpayRequest(keyId, keySecret, body) {
    return new Promise((resolve, reject) => {
        const postData = JSON.stringify(body);
        const auth = Buffer.from(`${keyId}:${keySecret}`).toString("base64");
        const options = {
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
                var _a, _b;
                try {
                    const parsed = JSON.parse(data);
                    if (res.statusCode && res.statusCode >= 200 && res.statusCode < 300) {
                        resolve(parsed);
                    }
                    else {
                        reject(new Error((_b = (_a = parsed.error) === null || _a === void 0 ? void 0 : _a.description) !== null && _b !== void 0 ? _b : `Razorpay API error (HTTP ${res.statusCode})`));
                    }
                }
                catch {
                    reject(new Error(`Invalid JSON response from Razorpay: ${data}`));
                }
            });
        });
        req.on("error", reject);
        req.write(postData);
        req.end();
    });
}
exports.createRazorpayOrder = functions.https.onCall(async (request) => {
    var _a, _b, _c, _d, _e, _f, _g, _h, _j, _k, _l, _m;
    // Require authentication
    if (!request.auth) {
        throw new functions.https.HttpsError("unauthenticated", "You must be signed in to create an order.");
    }
    const data = request.data;
    const amount = Number((_a = data === null || data === void 0 ? void 0 : data.amount) !== null && _a !== void 0 ? _a : 0);
    const currency = String((_b = data === null || data === void 0 ? void 0 : data.currency) !== null && _b !== void 0 ? _b : "INR");
    const receipt = String((_c = data === null || data === void 0 ? void 0 : data.receipt) !== null && _c !== void 0 ? _c : "");
    const notes = (_d = data === null || data === void 0 ? void 0 : data.notes) !== null && _d !== void 0 ? _d : {};
    if (!amount || amount <= 0) {
        throw new functions.https.HttpsError("invalid-argument", "amount must be a positive integer in paise");
    }
    if (!receipt) {
        throw new functions.https.HttpsError("invalid-argument", "receipt is required");
    }
    // Read Razorpay credentials
    const keyId = (_h = (_e = process.env.RAZORPAY_KEY_ID) !== null && _e !== void 0 ? _e : (_g = (_f = functions.config()) === null || _f === void 0 ? void 0 : _f.razorpay) === null || _g === void 0 ? void 0 : _g.key_id) !== null && _h !== void 0 ? _h : "";
    const keySecret = (_m = (_j = process.env.RAZORPAY_KEY_SECRET) !== null && _j !== void 0 ? _j : (_l = (_k = functions.config()) === null || _k === void 0 ? void 0 : _k.razorpay) === null || _l === void 0 ? void 0 : _l.key_secret) !== null && _m !== void 0 ? _m : "";
    // If keys are not configured, return a stub order for dev/testing
    if (!keyId || !keySecret) {
        functions.logger.warn("Razorpay keys not configured — returning stub order for development.");
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
            orderId: order.id,
            amount: order.amount,
            currency: order.currency,
        };
    }
    catch (err) {
        const message = err instanceof Error ? err.message : "Unknown error";
        functions.logger.error("Razorpay order creation failed", err);
        throw new functions.https.HttpsError("internal", `Failed to create Razorpay order: ${message}`);
    }
});
//# sourceMappingURL=createRazorpayOrder.js.map