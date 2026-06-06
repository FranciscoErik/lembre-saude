const swaggerDocument = {
  openapi: '3.0.3',
  info: {
    title: 'Lembre Saúde API',
    version: '1.0.0',
    description: 'API REST do sistema Lembre Saúde — TED 2 (Arquitetura de Dados e Contrato de API)',
  },
  servers: [{ url: '/api/v1', description: 'API v1' }],
  components: {
    securitySchemes: {
      bearerAuth: {
        type: 'http',
        scheme: 'bearer',
        bearerFormat: 'JWT',
      },
    },
    schemas: {
      Error: {
        type: 'object',
        properties: {
          code: { type: 'string' },
          message: { type: 'string' },
          details: { type: 'array', items: { type: 'object' } },
        },
      },
      User: {
        type: 'object',
        properties: {
          id: { type: 'string', format: 'uuid' },
          name: { type: 'string' },
          email: { type: 'string', format: 'email' },
          role: { type: 'string', enum: ['PATIENT', 'CAREGIVER'] },
        },
      },
      Medication: {
        type: 'object',
        properties: {
          id: { type: 'string' },
          userId: { type: 'string' },
          name: { type: 'string' },
          dosage: { type: 'string' },
          schedule: { type: 'string' },
          frequency: { type: 'string' },
          active: { type: 'boolean' },
        },
      },
      Dose: {
        type: 'object',
        properties: {
          id: { type: 'string' },
          medicationId: { type: 'string' },
          scheduledTime: { type: 'string' },
          status: { type: 'string', enum: ['PENDING', 'TAKEN', 'SKIPPED', 'POSTPONED'] },
          confirmedAt: { type: 'string', format: 'date-time', nullable: true },
        },
      },
    },
  },
  paths: {
    '/health': {
      get: {
        tags: ['Health'],
        summary: 'Verificação de disponibilidade',
        responses: {
          200: {
            description: 'API disponível',
            content: {
              'application/json': {
                schema: {
                  type: 'object',
                  properties: {
                    status: { type: 'string', example: 'ok' },
                    timestamp: { type: 'string', format: 'date-time' },
                  },
                },
              },
            },
          },
        },
      },
    },
    '/auth/register': {
      post: {
        tags: ['Auth'],
        summary: 'Cadastro de usuário',
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                type: 'object',
                required: ['name', 'email', 'password', 'role'],
                properties: {
                  name: { type: 'string' },
                  email: { type: 'string' },
                  password: { type: 'string' },
                  role: { type: 'string', enum: ['PATIENT', 'CAREGIVER'] },
                },
              },
            },
          },
        },
        responses: {
          201: { description: 'Usuário criado' },
          409: { description: 'E-mail já cadastrado' },
        },
      },
    },
    '/auth/login': {
      post: {
        tags: ['Auth'],
        summary: 'Autenticação',
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                type: 'object',
                required: ['email', 'password'],
                properties: {
                  email: { type: 'string' },
                  password: { type: 'string' },
                },
              },
            },
          },
        },
        responses: {
          200: { description: 'Login realizado' },
          401: { description: 'Credenciais inválidas' },
        },
      },
    },
    '/users/me': {
      get: {
        tags: ['Users'],
        summary: 'Perfil autenticado',
        security: [{ bearerAuth: [] }],
        responses: { 200: { description: 'Perfil do usuário' }, 401: { description: 'Não autenticado' } },
      },
      delete: {
        tags: ['Users'],
        summary: 'Exclusão de conta (LGPD)',
        security: [{ bearerAuth: [] }],
        responses: { 204: { description: 'Conta excluída' } },
      },
    },
    '/medications': {
      get: {
        tags: ['Medications'],
        summary: 'Listar medicamentos',
        security: [{ bearerAuth: [] }],
        responses: { 200: { description: 'Lista de medicamentos' } },
      },
      post: {
        tags: ['Medications'],
        summary: 'Cadastrar medicamento',
        security: [{ bearerAuth: [] }],
        responses: { 201: { description: 'Medicamento criado' } },
      },
    },
    '/medications/{id}': {
      patch: {
        tags: ['Medications'],
        summary: 'Editar medicamento',
        security: [{ bearerAuth: [] }],
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string' } }],
        responses: { 200: { description: 'Medicamento atualizado' } },
      },
      delete: {
        tags: ['Medications'],
        summary: 'Excluir medicamento',
        security: [{ bearerAuth: [] }],
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string' } }],
        responses: { 204: { description: 'Medicamento excluído' } },
      },
    },
    '/doses/{doseId}/confirm': {
      post: {
        tags: ['Doses'],
        summary: 'Confirmar dose',
        security: [{ bearerAuth: [] }],
        parameters: [{ name: 'doseId', in: 'path', required: true, schema: { type: 'string' } }],
        responses: { 200: { description: 'Dose confirmada' } },
      },
    },
    '/doses/adherence': {
      get: {
        tags: ['Doses'],
        summary: 'Histórico de aderência',
        security: [{ bearerAuth: [] }],
        responses: { 200: { description: 'Relatório de aderência' } },
      },
    },
    '/links/invite-code': {
      post: {
        tags: ['Links'],
        summary: 'Gerar código de vínculo',
        security: [{ bearerAuth: [] }],
        responses: { 201: { description: 'Código gerado' } },
      },
    },
    '/links/accept': {
      post: {
        tags: ['Links'],
        summary: 'Aceitar vínculo',
        security: [{ bearerAuth: [] }],
        responses: { 200: { description: 'Vínculo aceito' } },
      },
    },
    '/links/patients': {
      get: {
        tags: ['Links'],
        summary: 'Listar pacientes vinculados',
        security: [{ bearerAuth: [] }],
        responses: { 200: { description: 'Pacientes vinculados' } },
      },
    },
    '/users/me/consents': {
      get: {
        tags: ['Privacy'],
        summary: 'Consultar consentimentos',
        security: [{ bearerAuth: [] }],
        responses: { 200: { description: 'Lista de consentimentos' } },
      },
      post: {
        tags: ['Privacy'],
        summary: 'Registrar consentimento',
        security: [{ bearerAuth: [] }],
        responses: { 201: { description: 'Consentimento registrado' } },
      },
    },
    '/users/me/data-export': {
      post: {
        tags: ['Privacy'],
        summary: 'Exportar dados pessoais',
        security: [{ bearerAuth: [] }],
        responses: { 201: { description: 'Exportação solicitada' } },
      },
    },
  },
};

module.exports = swaggerDocument;
