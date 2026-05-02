import multer from "multer";
import path from "path";
import { env } from "../config/env.js";

const storage = multer.diskStorage({
  destination: (req, _file, cb) => {
    cb(null, env.uploadDir);
  },
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname);
    const name = `${Date.now()}-${Math.round(Math.random() * 1e9)}${ext}`;
    cb(null, name);
  }
});

const fileFilter = (_req, file, cb) => {
  // Log the mimetype for debugging
  console.log('File upload attempt:', {
    originalname: file.originalname,
    mimetype: file.mimetype,
    fieldname: file.fieldname
  });
  
  const isImage = file.mimetype.startsWith("image/");
  const isVideo = file.mimetype.startsWith("video/");
  
  if (isImage || isVideo) {
    cb(null, true);
  } else {
    cb(new Error(`Only images and videos are allowed. Received: ${file.mimetype}`), false);
  }
};

const proofFileFilter = (_req, file, cb) => {
  const extension = path.extname(file.originalname || "").toLowerCase();
  const octetAllowedExtensions = [
    ".jpg",
    ".jpeg",
    ".png",
    ".webp",
    ".gif",
    ".mp4",
    ".mov",
    ".webm",
    ".pdf",
    ".doc",
    ".docx"
  ];
  const isImage = file.mimetype.startsWith("image/");
  const isVideo = file.mimetype.startsWith("video/");
  const isPdf = file.mimetype === "application/pdf";
  const isDoc = file.mimetype === "application/msword";
  const isDocx = file.mimetype === "application/vnd.openxmlformats-officedocument.wordprocessingml.document";
  const isOctetStreamWithKnownExt =
    file.mimetype === "application/octet-stream" && octetAllowedExtensions.includes(extension);

  if (isImage || isVideo || isPdf || isDoc || isDocx || isOctetStreamWithKnownExt) {
    cb(null, true);
  } else {
    cb(new Error(`Only image, video, and document files are allowed. Received: ${file.mimetype}`), false);
  }
};

// For single photo/video upload
export const upload = multer({ 
  storage, 
  fileFilter, 
  limits: { fileSize: 100e6 } // 100MB for videos
});

// For multiple files (photo and video)
export const uploadMultiple = multer({ 
  storage, 
  fileFilter, 
  limits: { fileSize: 100e6 }
});

// For resolution proof uploads (image/video/document)
export const uploadProof = multer({
  storage,
  fileFilter: proofFileFilter,
  limits: { fileSize: 100e6 }
});
