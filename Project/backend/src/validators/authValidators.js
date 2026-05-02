import { z } from "zod";

const phoneValidator = z
  .preprocess((value) => {
    if (typeof value !== "string") return undefined;
    const trimmed = value.trim();
    return trimmed.length === 0 ? undefined : trimmed;
  },
  z
    .string()
    .superRefine((value, ctx) => {
      const digits = value.replace(/\D/g, "");
      if (digits.length < 10 || digits.length > 15) {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          message: "Phone number must contain between 10 and 15 digits"
        });
      }
    }))
  .optional();

export const registerSchema = z.object({
  name: z.string().min(2),
  email: z.string().email(),
  phone: phoneValidator,
  password: z.string().min(8),
  role: z.enum(["citizen", "admin", "department"]).default("citizen"),
  departmentId: z.number().int().nullable().optional(),
  department_name: z.string().optional(),
  department_type: z.string().optional()
});

export const loginSchema = z
  .object({
    email: z.string().email().optional(),
    phone: phoneValidator,
    password: z.string().min(8)
  })
  .superRefine((data, ctx) => {
    if (!data.email && !data.phone) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: "Email or phone is required",
        path: ["email"]
      });
    }
  });
