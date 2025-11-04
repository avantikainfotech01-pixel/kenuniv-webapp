// 🌐 Base URL
// For Android Emulator use: http://10.0.2.2:5000
// For iOS Simulator or Web use: http://localhost:5000
// For real devices, replace with your system's IP (e.g. http://192.168.1.5:5000)
const String baseUrl = "http://api.kenuniv.com";
// --- AUTH ---
const String loginEndpoint = "$baseUrl/login";
const String adminLoginEndpoint = "$baseUrl/api/admin/user-master-login";

const String registerEndpoint = "$baseUrl/api/auth/register";

// --- USER MASTER (Admin Panel) ---
const String userMasterEndpoint = "$baseUrl/api/admin/user-master";
const String userMasterGet = "$baseUrl/api/admin/user-master";

// --- SCHEMES ---
const String schemesEndpoint = "$baseUrl/admin/schemes";

// --- STOCKS ---
const String stocksEndpoint = "$baseUrl/admin/stocks";

// --- QR Codes ---
const String generateQrsPdfEndpoint = "$baseUrl/admin/generate-qrs-pdf";
const String qrListEndpoint = "$baseUrl/admin/qrs";
const String activateQrEndpoint = "$baseUrl/admin/activate-qr";
const String printQrEndpoint = "$baseUrl/admin/print-qr";

// --- WALLET ---
const String walletHistoryEndpoint = "$baseUrl/wallet/history";
const String walletAddPointsEndpoint = "$baseUrl/wallet/add";

// --- NEWS ---
const String newsEndpoint = "$baseUrl/api/news";

// --- KYC ---
const String kycUploadEndpoint = "$baseUrl/kyc/upload";
