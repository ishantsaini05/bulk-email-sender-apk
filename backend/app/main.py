from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api.v1.endpoints import auth, email_config, emails

app = FastAPI(
    title="Premium Email App API",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register routers
app.include_router(auth.router, prefix="/api/v1/auth", tags=["Authentication"])
app.include_router(email_config.router, prefix="/api/v1/email-config", tags=["Email Configuration"])
app.include_router(emails.router, prefix="/api/v1/emails", tags=["Emails"])

@app.get("/")
def root():
    return {"message": "Premium Email App API", "version": "1.0.0"}

@app.get("/health")
def health_check():
    return {"status": "healthy"}