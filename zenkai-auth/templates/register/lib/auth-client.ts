const AUTH_API_URL = "AUTH_API_URL";

type LoginInput = {
  email: string;
  password: string;
};

type RegisterInput = {
  name?: string;
  email: string;
  password: string;
};

type UserLookupResponse = {
  id: string;
};

type CreateUserResponse = {
  id: string;
  user_id: string;
};

function getErrorMessage(payload: unknown, fallbackMessage: string): string {
  if (payload && typeof payload === "object" && "message" in payload) {
    const value = payload.message;
    if (typeof value === "string" && value.trim().length > 0) {
      return value;
    }
  }
  return fallbackMessage;
}

async function parseError(response: Response, fallbackMessage: string): Promise<never> {
  let payload: unknown = null;
  try {
    payload = await response.json();
  } catch {
    throw new Error(fallbackMessage);
  }
  throw new Error(getErrorMessage(payload, fallbackMessage));
}

async function getUserByEmail(email: string): Promise<UserLookupResponse> {
  const response = await fetch(`${AUTH_API_URL}/user`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json"
    },
    credentials: "include",
    body: JSON.stringify({ email: email.toLowerCase().trim() })
  });

  if (!response.ok) {
    return parseError(response, "No account found for this email.");
  }

  return response.json();
}

async function login(payload: LoginInput): Promise<void> {
  const user = await getUserByEmail(payload.email);

  const response = await fetch(`${AUTH_API_URL}/password/login`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json"
    },
    credentials: "include",
    body: JSON.stringify({
      user_id: user.id,
      password: payload.password
    })
  });

  if (!response.ok) {
    return parseError(response, "Invalid email or password.");
  }
}

async function createUser(email: string): Promise<CreateUserResponse> {
  const response = await fetch(`${AUTH_API_URL}/users`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json"
    },
    credentials: "include",
    body: JSON.stringify({ email: email.toLowerCase().trim() })
  });

  if (!response.ok) {
    return parseError(response, "Unable to create account.");
  }

  return response.json();
}

async function setPassword(userId: string, password: string): Promise<void> {
  const response = await fetch(`${AUTH_API_URL}/password`, {
    method: "PUT",
    headers: {
      "Content-Type": "application/json"
    },
    credentials: "include",
    body: JSON.stringify({
      user_id: userId,
      password
    })
  });

  if (!response.ok) {
    return parseError(
      response,
      "Account was created but password setup failed. Check backend email verification and password settings."
    );
  }
}

async function register(payload: RegisterInput): Promise<void> {
  const user = await createUser(payload.email);
  await setPassword(user.user_id ?? user.id, payload.password);
}

export const authClient = {
  login,
  register
};
