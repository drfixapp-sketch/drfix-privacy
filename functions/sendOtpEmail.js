/**
 * Dr. Fix Cloud Function: sendOtpEmail
 * 
 * وظيفة سحابية خفيفة واقتصادية (Lightweight Serverless Function)
 * تعمل تلقائياً بمجرد إنشاء وثيقة OTP جديدة في مسار: users/{uid}/security/email_otp
 * وتقوم بإرسال كود الـ 6 أرقام مباشرة إلى صندوق الوارد (Inbox) لبريد الفني عبر Nodemailer.
 */

const functions = require("firebase-functions");
const nodemailer = require("nodemailer");

// إعداد خادم الإرسال (SMTP Transporter)
// يمكنك استخدام Gmail App Password، أو Brevo (Sendinblue)، أو SendGrid المجاني
const transporter = nodemailer.createTransport({
  service: process.env.SMTP_SERVICE || "gmail", // e.g. 'gmail' or host: 'smtp-relay.brevo.com'
  auth: {
    user: process.env.SMTP_USER, // بريدك الإلكتروني المعتمد
    pass: process.env.SMTP_PASS, // كلمة مرور التطبيق (App Password)
  },
});

exports.sendOtpEmail = functions.firestore
  .document("users/{uid}/security/email_otp")
  .onCreate(async (snap, context) => {
    const data = snap.data();
    if (!data) return null;

    const email = data.email;
    const otpCode = data.code;

    if (!email || !otpCode) {
      console.error("Missing email or otpCode in document.");
      return null;
    }

    const mailOptions = {
      from: `"Dr. Fix Engineering" <${process.env.SMTP_USER || "noreply@drfix.app"}>`,
      to: email,
      subject: `رمز التحقق من حسابك في تطبيق Dr. Fix (${otpCode})`,
      text: `مرحباً بك في منصة Dr. Fix الهندسية.\nرمز التحقق الخاص بك هو: ${otpCode}\nصلاحية هذا الرمز هي 24 ساعة فقط.`,
      html: `
        <div dir="rtl" style="font-family: Arial, sans-serif; max-width: 520px; margin: auto; padding: 24px; border: 1px solid #e2e8f0; border-radius: 16px; background-color: #ffffff;">
          <div style="text-align: center; margin-bottom: 24px;">
            <h1 style="color: #0f172a; margin: 0; font-size: 24px;">د. فيكس | Dr. Fix</h1>
            <p style="color: #64748b; font-size: 13px; margin-top: 4px;">منصة التشخيص الهندسي والذكاء الاصطناعي</p>
          </div>
          <div style="background-color: #f8fafc; border-radius: 12px; padding: 20px; text-align: center; margin-bottom: 20px;">
            <p style="color: #334155; font-size: 14px; margin-bottom: 12px;">رمز التحقق السري لتفعيل حسابك:</p>
            <div style="font-size: 32px; font-weight: bold; letter-spacing: 8px; color: #0f172a; background: #ffffff; padding: 12px 24px; border-radius: 8px; display: inline-block; border: 1px solid #cbd5e1;">
              ${otpCode}
            </div>
            <p style="color: #ef4444; font-size: 12px; margin-top: 14px; font-weight: bold;">⏱️ صلاحية الرمز: 24 ساعة فقط</p>
          </div>
          <p style="color: #64748b; font-size: 12px; line-height: 1.6; text-align: justify; margin: 0;">
            إذا لم تقم بطلب هذا الرمز، يرجى تجاهل هذه الرسالة. لا تشارك هذا الرمز مع أي شخص لحماية بياناتك.
          </p>
          <hr style="border: none; border-top: 1px solid #e2e8f0; margin: 20px 0;" />
          <p style="color: #94a3b8; font-size: 11px; text-align: center; margin: 0;">© 2026 Dr. Fix Engineering Platform. All rights reserved.</p>
        </div>
      `,
    };

    try {
      await transporter.sendMail(mailOptions);
      console.log(`✅ Verification email successfully sent to: ${email}`);
      return snap.ref.update({ email_sent: true, sent_at: new Date() });
    } catch (error) {
      console.error("❌ Error sending email:", error);
      return snap.ref.update({ email_sent: false, send_error: error.toString() });
    }
  });
