import os

import uvicorn


if __name__ == "__main__":
    host = os.getenv("HOST", "0.0.0.0")
    port = int(os.getenv("PORT", "8001"))
    reload_mode = os.getenv("RELOAD", "true").lower() in {"1", "true", "yes", "y"}

    uvicorn.run(
        "app.main:app",
        host=host,
        port=port,
        reload=reload_mode,
    )
