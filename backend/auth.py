from fastapi import Security, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
import firebase_admin
from firebase_admin import auth, credentials

# Initialize Firebase app if not already initialized
try:
    firebase_admin.get_app()
except ValueError:
    # Providing the projectId allows verify_id_token to work without a full service account JSON
    firebase_admin.initialize_app(options={'projectId': 'spendly360'})

security = HTTPBearer()

def verify_token(credentials: HTTPAuthorizationCredentials = Security(security)):
    """
    Dependency to verify Firebase ID tokens.
    Extracts the Bearer token from the Authorization header and verifies it.
    Returns the decoded token dictionary (which includes 'uid').
    """
    token = credentials.credentials
    try:
        decoded_token = auth.verify_id_token(token)
        return decoded_token
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid authentication credentials: {e}",
            headers={"WWW-Authenticate": "Bearer"},
        )
