const { z } = require('zod');

const registerSchema = z.object({
  name: z.string().min(2, 'Nome deve ter pelo menos 2 caracteres'),
  email: z.string().email('E-mail inválido'),
  password: z.string().min(6, 'Senha deve ter pelo menos 6 caracteres'),
  role: z.enum(['PATIENT', 'CAREGIVER']),
});

const loginSchema = z.object({
  email: z.string().email('E-mail inválido'),
  password: z.string().min(1, 'Senha obrigatória'),
});

const medicationSchema = z.object({
  name: z.string().min(1, 'Nome obrigatório'),
  dosage: z.string().min(1, 'Dosagem obrigatória'),
  schedule: z.string().min(1, 'Horário obrigatório'),
  frequency: z.string().min(1, 'Frequência obrigatória'),
  active: z.boolean().optional().default(true),
});

const medicationPatchSchema = medicationSchema.partial();

const confirmDoseSchema = z.object({
  status: z.enum(['TAKEN', 'SKIPPED', 'POSTPONED']),
});

const consentSchema = z.object({
  type: z.string().min(1, 'Tipo de consentimento obrigatório'),
});

const acceptLinkSchema = z.object({
  inviteCode: z.string().min(1, 'Código de convite obrigatório'),
});

const notificationSettingsSchema = z.object({
  enabled: z.boolean(),
  remindBeforeMinutes: z.number().int().min(0).max(120).optional(),
});

module.exports = {
  registerSchema,
  loginSchema,
  medicationSchema,
  medicationPatchSchema,
  confirmDoseSchema,
  consentSchema,
  acceptLinkSchema,
  notificationSettingsSchema,
};
