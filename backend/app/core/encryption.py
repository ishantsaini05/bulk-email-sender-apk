"""
Encryption utilities for securing email passwords
"""
from cryptography.fernet import Fernet
import base64
import os
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
from app.config import settings

# Generate a key from settings secret key
def get_encryption_key():
    """Get encryption key from settings"""
    secret_key = settings.SECRET_KEY.encode()
    salt = b'premium_email_app_salt'  # You can make this configurable
    
    kdf = PBKDF2HMAC(
        algorithm=hashes.SHA256(),
        length=32,
        salt=salt,
        iterations=100000,
    )
    
    key = base64.urlsafe_b64encode(kdf.derive(secret_key))
    return key

def encrypt_password(password: str):
    """Encrypt a password"""
    key = get_encryption_key()
    fernet = Fernet(key)
    
    encrypted_password = fernet.encrypt(password.encode())
    
    # Generate IV (Fernet handles this internally, but we return the token)
    # For Fernet, the first part of the token is essentially the IV
    iv = base64.urlsafe_b64encode(os.urandom(16)).decode()
    
    return encrypted_password.decode(), iv

def decrypt_password(encrypted_password: str, iv: str) -> str:
    """Decrypt a password"""
    try:
        key = get_encryption_key()
        fernet = Fernet(key)
        
        decrypted_password = fernet.decrypt(encrypted_password.encode())
        return decrypted_password.decode()
    except Exception as e:
        raise ValueError(f"Decryption failed: {str(e)}")