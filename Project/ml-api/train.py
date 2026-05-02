import pandas as pd
import pickle
import matplotlib.pyplot as plt

# ML imports
from sklearn.model_selection import train_test_split
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.svm import LinearSVC
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix, ConfusionMatrixDisplay

# -----------------------------
# STEP 1: Load Dataset
# -----------------------------
data = pd.read_csv("cat_com.csv", skipinitialspace=True)

# Clean column names
data.columns = data.columns.str.strip()

print("Columns in dataset:", data.columns)

# -----------------------------
# STEP 2: Data Cleaning
# -----------------------------
data["text"] = data["text"].astype(str).str.lower().str.strip()

data["category"] = data["category"].astype(str).str.strip()
data["category"] = data["category"].str.replace(" ", "_")

# Remove duplicates
data = data.drop_duplicates()

# Remove classes with < 2 samples
counts = data["category"].value_counts()
data = data[data["category"].isin(counts[counts > 1].index)]

print("\nClass Distribution:\n")
print(data["category"].value_counts())

# -----------------------------
# STEP 3: Features & Labels
# -----------------------------
texts = data["text"]
labels = data["category"]

# -----------------------------
# STEP 4: Train-Test Split
# -----------------------------
X_train, X_test, y_train, y_test = train_test_split(
    texts,
    labels,
    test_size=0.2,
    stratify=labels,
    random_state=42
)

# -----------------------------
# STEP 5: TF-IDF Vectorization
# -----------------------------
vectorizer = TfidfVectorizer(
    lowercase=True,
    stop_words='english',
    ngram_range=(1, 2),
    max_features=7000,
    min_df=2
)

X_train_vec = vectorizer.fit_transform(X_train)
X_test_vec = vectorizer.transform(X_test)

# -----------------------------
# STEP 6: Train Model
# -----------------------------
model = LinearSVC(class_weight='balanced')
model.fit(X_train_vec, y_train)

# -----------------------------
# STEP 7: Evaluation
# -----------------------------
y_pred = model.predict(X_test_vec)

accuracy = accuracy_score(y_test, y_pred)

print("\n✅ Accuracy:", accuracy)
print("\n📊 Classification Report:\n")
print(classification_report(y_test, y_pred, zero_division=1))

cm = confusion_matrix(y_test, y_pred)

print("\n🧠 Confusion Matrix:\n")
print(cm)

# -----------------------------
# 📊 GRAPHS SECTION
# -----------------------------

# 1️⃣ Accuracy Graph
plt.figure()
plt.bar(["Model Accuracy"], [accuracy])
plt.title("Model Accuracy")
plt.ylabel("Accuracy")
plt.ylim(0, 1)
plt.show()

# 2️⃣ Confusion Matrix Graph
disp = ConfusionMatrixDisplay(confusion_matrix=cm)
disp.plot()
plt.title("Confusion Matrix")
plt.show()

# 3️⃣ Precision / Recall / F1 Graph
report = classification_report(y_test, y_pred, output_dict=True)
df = pd.DataFrame(report).transpose()

# Remove avg rows
df = df.iloc[:-3]

df[["precision", "recall", "f1-score"]].plot(kind="bar")
plt.title("Precision, Recall, F1-score per Class")
plt.ylabel("Score")
plt.xticks(rotation=45)
plt.show()

# 4️⃣ Dataset Distribution Graph
data["category"].value_counts().plot(kind="bar")
plt.title("Dataset Class Distribution")
plt.xlabel("Category")
plt.ylabel("Count")
plt.show()

# -----------------------------
# STEP 8: Save Model
# -----------------------------
pickle.dump(model, open("model.pkl", "wb"))
pickle.dump(vectorizer, open("vectorizer.pkl", "wb"))

print("\n🎯 Model and vectorizer saved successfully!")