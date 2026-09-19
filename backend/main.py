from fastapi import FastAPI

app = FastAPI(
    title="Spendly API",
    description="Backend API for the Spendly personal finance app.",
    version="1.0.0"
)

@app.get("/")
def read_root():
    return {"message": "Hello from the Spendly API!"}

@app.get("/health")
def health_check():
    return {"status": "healthy"}
