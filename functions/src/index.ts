import * as admin from "firebase-admin";

import { createRazorpayOrder } from "./createRazorpayOrder";
import { generateQrData } from "./generateQrData";
import { onBookingCreated } from "./onBookingCreated";
import { verifyPayment } from "./verifyPayment";

admin.initializeApp();

export {
  createRazorpayOrder,
  verifyPayment,
  onBookingCreated,
  generateQrData,
};
