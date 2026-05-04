import uuid

from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import User
from app.utils.security import decode_access_token


oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/auth/login")

CREDENTIALS_EXC = HTTPException(
    status_code=status.HTTP_401_UNAUTHORIZED,
    detail="Could not validate credentials",
    headers={"WWW-Authenticate": "Bearer"},
)


def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db),
) -> User:
    try:
        payload = decode_access_token(token)
        sub = payload.get("sub")
        if sub is None:
            raise CREDENTIALS_EXC
        user_id = uuid.UUID(sub)
    except (JWTError, ValueError):
        raise CREDENTIALS_EXC

    user = db.query(User).filter(User.id == user_id).first()
    if user is None:
        raise CREDENTIALS_EXC
    return user
