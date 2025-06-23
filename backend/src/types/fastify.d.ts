import '@fastify/jwt'

declare module '@fastify/jwt' {
  interface FastifyJWT {
    payload: {
      id: string
      email: string
      username: string
      role: string
    }
    user: {
      id: string
      email: string
      username: string
      role: string
    }
  }
}

declare module 'fastify' {
  interface FastifyRequest {
    user?: {
      id: string
      email: string
      username: string
      role: string
    }
  }
}
