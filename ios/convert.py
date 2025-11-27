import tensorflow as tf

MODEL_PATH = "imu_cnn_lstm.keras"
OUTPUT_PATH = "imu_cnn_lstm.tflite"

print("🔍 Chargement du modèle Keras...")
model = tf.keras.models.load_model(MODEL_PATH)
print("✅ Modèle chargé.")

print("🔄 Conversion en TFLite avec ops select (Flex)...")
converter = tf.lite.TFLiteConverter.from_keras_model(model)
converter.target_spec.supported_ops = [
    tf.lite.OpsSet.TFLITE_BUILTINS,
    tf.lite.OpsSet.SELECT_TF_OPS,
]

tflite_model = converter.convert()

print("💾 Écriture du modèle .tflite...")
with open(OUTPUT_PATH, "wb") as f:
    f.write(tflite_model)

print(f"🎉 Conversion terminée ! Modèle enregistré : {OUTPUT_PATH}")
