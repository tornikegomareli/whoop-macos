import type { Environment } from "./environment";
import { handleRequest } from "./request-handler";

export default {
  async fetch(request: Request, env: Environment): Promise<Response> {
    return handleRequest(request, env, fetch);
  },
};

