from fastapi import FastAPI
import pickle

app = FastAPI()

model = pickle.load(open("model.pkl", "rb"))
vectorizer = pickle.load(open("vectorizer.pkl", "rb"))

@app.post("/predict")
def predict(data: dict):
    text = data.get("text", "")

    if not text:
        return {"error": "Empty input"}

    X = vectorizer.transform([text])
    prediction = model.predict(X)[0]

    # optional (if model supports probability)
    confidence = None
    if hasattr(model, "predict_proba"):
        confidence = max(model.predict_proba(X)[0])

    return {
        "category": prediction,
        "confidence": confidence
    }