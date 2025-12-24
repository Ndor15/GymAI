const functions = require('firebase-functions');
const { OpenAI } = require('openai');

// Lazy initialization of OpenAI (only when needed)
let openaiInstance = null;

function getOpenAI() {
  if (!openaiInstance) {
    const apiKey = process.env.OPENAI_API_KEY;
    if (!apiKey) {
      throw new Error('OPENAI_API_KEY is not configured. Run: firebase functions:secrets:set OPENAI_API_KEY');
    }
    openaiInstance = new OpenAI({ apiKey });
  }
  return openaiInstance;
}

/**
 * Generate initial workout program based on user objectives
 */
exports.generateWorkoutProgram = functions.https.onCall(async (data, context) => {
  // Check authentication
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { objective, level, frequency, splitType, focusGroups } = data;

  try {
    const openai = getOpenAI();
    const completion = await openai.chat.completions.create({
      model: 'gpt-4',
      messages: [
        {
          role: 'system',
          content: `Tu es un coach sportif expert en musculation et programmation d'entraînement.
Tu dois créer des programmes personnalisés basés sur les objectifs et le niveau de l'utilisateur.
Réponds UNIQUEMENT en JSON valide, sans texte additionnel.`
        },
        {
          role: 'user',
          content: `Crée un programme d'entraînement hebdomadaire avec ces paramètres :
- Objectif : ${objective}
- Niveau : ${level}
- Fréquence : ${frequency} séances/semaine
- Split : ${splitType}
- Focus groupes musculaires : ${focusGroups || 'Équilibré'}

Le programme doit inclure :
1. Un planning hebdomadaire (quel type de séance chaque jour)
2. Pour chaque type de séance (PUSH/PULL/LEGS/etc), une liste d'exercices recommandés
3. Des guidelines de volume (sets/reps) selon l'objectif

Format JSON attendu :
{
  "weeklySchedule": [
    {"day": "Lundi", "sessionType": "PUSH", "focus": "Pecs + Épaules + Triceps"},
    ...
  ],
  "sessionTemplates": {
    "PUSH": {
      "exercises": [
        {"name": "Développé couché", "sets": "3-4", "reps": "8-12", "priority": "high"},
        ...
      ],
      "totalVolume": "15-20 sets",
      "duration": "60-90 min"
    },
    ...
  },
  "progressionGuidelines": {
    "weightProgression": "...",
    "deloadWeek": "..."
  }
}`
        }
      ],
      temperature: 0.7,
      max_tokens: 2000,
    });

    const programData = JSON.parse(completion.choices[0].message.content);

    return {
      success: true,
      program: programData,
      generatedAt: new Date().toISOString(),
    };

  } catch (error) {
    console.error('Error generating workout program:', error);
    throw new functions.https.HttpsError('internal', 'Failed to generate workout program');
  }
});

/**
 * Get exercise recommendation during workout
 */
exports.getExerciseRecommendation = functions.https.onCall(async (data, context) => {
  // Check authentication
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const {
    userProfile,      // {objective, level, splitType}
    currentSession,   // {type: "PUSH", exercisesDone: [...], muscleGroupsWorked: [...]}
    exerciseHistory,  // {exerciseName: [{date, sets, reps, weight}, ...]}
    recentTrends,     // {last4WeeksVolume, progressionRate, plateauDetected}
  } = data;

  try {
    const openai = getOpenAI();
    const completion = await openai.chat.completions.create({
      model: 'gpt-4',
      messages: [
        {
          role: 'system',
          content: `Tu es un coach sportif expert qui recommande des exercices intelligents pendant une séance.
Tu dois :
- Rester cohérent avec le type de séance (PUSH/PULL/LEGS)
- Éviter de proposer un exercice déjà fait dans la séance
- Varier les angles et parties du muscle
- Proposer une progression réaliste basée sur l'historique
- Détecter les plateaux et adapter
Réponds UNIQUEMENT en JSON valide.`
        },
        {
          role: 'user',
          content: `Recommande le prochain exercice pour cette séance :

Profil utilisateur :
- Objectif : ${userProfile.objective}
- Niveau : ${userProfile.level}
- Split : ${userProfile.splitType}

Séance en cours :
- Type : ${currentSession.type}
- Exercices déjà faits : ${JSON.stringify(currentSession.exercisesDone)}
- Groupes musculaires travaillés : ${JSON.stringify(currentSession.muscleGroupsWorked)}

Historique (dernières 4 semaines) :
${JSON.stringify(exerciseHistory, null, 2)}

Tendances :
- Volume 4 dernières semaines : ${recentTrends.last4WeeksVolume}kg
- Taux de progression : ${recentTrends.progressionRate}
- Plateau détecté : ${recentTrends.plateauDetected ? 'Oui' : 'Non'}

Format JSON attendu :
{
  "exercise": {
    "name": "Nom de l'exercice",
    "targetSets": 3,
    "targetReps": "8-12",
    "suggestedWeight": 25,
    "muscleGroup": "Pecs",
    "angle": "Incliné"
  },
  "reasoning": "Pourquoi cet exercice maintenant (2-3 phrases courtes)",
  "progressionNotes": "Notes sur le poids suggéré et progression",
  "alternatives": ["Exercice alternatif 1", "Exercice alternatif 2"]
}`
        }
      ],
      temperature: 0.8,
      max_tokens: 800,
    });

    const recommendation = JSON.parse(completion.choices[0].message.content);

    return {
      success: true,
      recommendation,
      timestamp: new Date().toISOString(),
    };

  } catch (error) {
    console.error('Error getting exercise recommendation:', error);
    throw new functions.https.HttpsError('internal', 'Failed to get exercise recommendation');
  }
});

/**
 * Analyze progression and suggest adjustments
 */
exports.analyzeProgression = functions.https.onCall(async (data, context) => {
  // Check authentication
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { userProfile, exerciseHistory, weeklyStats } = data;

  try {
    const openai = getOpenAI();
    const completion = await openai.chat.completions.create({
      model: 'gpt-4',
      messages: [
        {
          role: 'system',
          content: `Tu es un coach sportif expert en analyse de progression.
Tu détectes les plateaux, surcharge, sous-récupération, et proposes des ajustements intelligents.
Réponds UNIQUEMENT en JSON valide.`
        },
        {
          role: 'user',
          content: `Analyse la progression de cet utilisateur :

Profil :
- Objectif : ${userProfile.objective}
- Niveau : ${userProfile.level}

Historique (8 dernières semaines) :
${JSON.stringify(exerciseHistory, null, 2)}

Stats hebdomadaires :
${JSON.stringify(weeklyStats, null, 2)}

Format JSON attendu :
{
  "overallProgression": "Excellente | Bonne | Stagnante | Régressive",
  "plateausDetected": [
    {"exercise": "Développé couché", "since": "3 semaines", "reason": "..."}
  ],
  "recommendations": [
    {"type": "deload | variation | intensity", "description": "...", "priority": "high"}
  ],
  "nextWeekAdjustments": {
    "volumeChange": "+5% | -10% | maintenir",
    "intensityChange": "...",
    "suggestedDeload": false
  }
}`
        }
      ],
      temperature: 0.7,
      max_tokens: 1000,
    });

    const analysis = JSON.parse(completion.choices[0].message.content);

    return {
      success: true,
      analysis,
      analyzedAt: new Date().toISOString(),
    };

  } catch (error) {
    console.error('Error analyzing progression:', error);
    throw new functions.https.HttpsError('internal', 'Failed to analyze progression');
  }
});
