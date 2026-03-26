const functions = require("firebase-functions");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

admin.initializeApp();
const db = admin.firestore();

const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: process.env.MAIL_USER,
    pass: process.env.MAIL_PASS,
  },
});

function generateOTP() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

exports.sendLoginOTP = functions.https.onCall(async (data, context) => {
  const { email, uid } = data;

  if (!email || !uid) {
    throw new functions.https.HttpsError("invalid-argument", "Thiếu email hoặc uid");
  }

  const otp = generateOTP();
  const expiresAt = Date.now() + 10 * 60 * 1000;

  await db.collection("otps").doc(uid).set({
    otp,
    expiresAt,
    email,
    attempts: 0,
  });

const mailOptions = {
    from: `"SMEE Security" <${process.env.MAIL_USER}>`,
    to: email,
    subject: "Mã xác thực đăng nhập SMEE",
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 480px; margin: auto; padding: 32px; border-radius: 16px; background: #1a1a2e; color: #fff;">
        <h2 style="color: #e91e8c; margin-bottom: 8px;">SMEE 📸</h2>
        <p style="color: #ccc; margin-bottom: 24px;">Bạn đang đăng nhập trên thiết bị mới. Vui lòng nhập mã OTP bên dưới:</p>
        <div style="background: #16213e; border-radius: 12px; padding: 24px; text-align: center; margin-bottom: 24px;">
          <span style="font-size: 40px; font-weight: bold; letter-spacing: 12px; color: #e91e8c;">${otp}</span>
        </div>
        <p style="color: #999; font-size: 13px;">Mã có hiệu lực trong <strong style="color:#fff;">10 phút</strong>. Không chia sẻ mã này với ai.</p>
        <p style="color: #666; font-size: 12px; margin-top: 16px;">Nếu bạn không thực hiện đăng nhập này, hãy đổi mật khẩu ngay.</p>
      </div>
    `,
  };

  await transporter.sendMail(mailOptions);
  return { success: true, message: "OTP đã được gửi đến email của bạn" };
});

exports.verifyLoginOTP = functions.https.onCall(async (data, context) => {
  const { uid, otp } = data;

  if (!uid || !otp) {
    throw new functions.https.HttpsError("invalid-argument", "Thiếu uid hoặc otp");
  }

  const doc = await db.collection("otps").doc(uid).get();
  if (!doc.exists) {
    throw new functions.https.HttpsError("not-found", "Không tìm thấy yêu cầu OTP");
  }

  const record = doc.data();

  if (record.attempts >= 5) {
    await db.collection("otps").doc(uid).delete();
    throw new functions.https.HttpsError("resource-exhausted", "Quá nhiều lần thử sai. Vui lòng yêu cầu OTP mới.");
  }

  if (Date.now() > record.expiresAt) {
    await db.collection("otps").doc(uid).delete();
    throw new functions.https.HttpsError("deadline-exceeded", "Mã OTP đã hết hạn");
  }

  if (record.otp !== otp) {
    await db.collection("otps").doc(uid).update({ attempts: record.attempts + 1 });
    throw new functions.https.HttpsError("unauthenticated", "Mã OTP không đúng");
  }

  await db.collection("otps").doc(uid).delete();
  return { success: true };
});