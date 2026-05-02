/**
 * Rule-based NLP classification service
 * Classifies complaints into departments based on keywords
 */

// Define department keywords mapping
const departmentKeywords = {
  "Road": [
    "road",
    "roads",
    "road maintenance",
    "pothole",
    "potholes",
    "road crack",
    "road cracks",
    "cracked road",
    "broken road",
    "damaged road",
    "road damaged",
    "manhole",
    "missing manhole cover",
    "missing manhole covers",
    "road damage",
    "accident due to road damage",
    "road accident due to damage",
    "road accidents due to damage",
    "road accident",
    "pavement",
    "asphalt",
    "road surface",
    "road safety",
    "road hazard",
    "pothole hazard",
    "road deterioration",
    "sidewalk",
    "footpath",
    "broken footpath",
    "broken footpaths",
    "damaged speed breaker",
    "damaged speed breakers",
    "unauthorized road digging"
  ],
  "Garbage & Waste Management": [
    "garbage",
    "waste",
    "trash",
    "litter",
    "dumping",
    "garbage dump",
    "waste dump",
    "dirty",
    "filthy",
    "sanitation",
    "garbage bins",
    "waste management",
    "refuse",
    "debris",
    "rubbish",
    "sweeping",
    "cleaning",
    "garbage not collected",
    "overflowing dustbin",
    "no dustbin in area",
    "irregular waste pickup",
    "dumping in open areas",
    "bad smell from waste",
    "dead animal disposal"
  ],
  "Water": [
    "water leak",
    "pipeline",
    "drainage",
    "drain clogged",
    "waterlogging",
    "water supply",
    "water quality",
    "sewage",
    "sewer",
    "water pipe",
    "leakage",
    "water crisis",
    "water shortage",
    "drain",
    "stagnant water",
    "flooding"
  ],
  "Street Light": [
    "street light",
    "electric pole",
    "streetlight",
    "electricity",
    "power",
    "electrical hazard",
    "power outage",
    "light",
    "lamp",
    "bulb",
    "high voltage",
    "electrical accident",
    "broken pole",
    "damaged pole",
    "electrical damage"
  ],
  "Public Transport": [
    "bus delay",
    "overcrowding",
    "bus not stopping at stop",
    "driver rash driving",
    "bus breakdown",
    "dirty buses",
    "route change without notice",
    "lack of buses on route",
    "bus",
    "transport"
  ],

};

/**
 * Classify complaint based on description
 * @param {string} description - The complaint description
 * @returns {object} Classification result with department and confidence
 */
export const classifyComplaint = (description) => {
  // Input validation
  if (!description || typeof description !== "string" || description.trim().length === 0) {
    return {
      department: "General",
      confidence: 0,
      matchedKeywords: []
    };
  }

  // Normalize text to improve keyword matching
  const normalizedText = description
    .toLowerCase()
    .replace(/[–—-]/g, " ")
    .replace(/[^a-z0-9\s]/g, " ")
    .replace(/\s+/g, " ")
    .trim();
  
  // Score each department based on keyword matches
  const departmentScores = {};
  const departmentMatches = {};

  Object.entries(departmentKeywords).forEach(([dept, keywords]) => {
    let score = 0;
    const matches = [];

    keywords.forEach((keyword) => {
      // Check if keyword appears in the description
      if (normalizedText.includes(keyword)) {
        score += 1;
        matches.push(keyword);
      }
    });

    if (score > 0) {
      departmentScores[dept] = score;
      departmentMatches[dept] = matches;
    }
  });

  // Find department with highest score
  if (Object.keys(departmentScores).length === 0) {
    return {
      department: "General",
      confidence: 0,
      matchedKeywords: []
    };
  }

  const maxScore = Math.max(...Object.values(departmentScores));
  const classifiedDept = Object.keys(departmentScores).find(
    (dept) => departmentScores[dept] === maxScore
  );

  // Calculate confidence (0-1)
  const confidence = Math.min(maxScore / 3, 1); // Normalize by typical max keywords

  return {
    department: classifiedDept || "General",
    confidence,
    matchedKeywords: departmentMatches[classifiedDept] || [],
    scores: departmentScores // For debugging
  };
};

/**
 * Extend classification keywords dynamically
 * Useful for admin to add more keywords to department
 * @param {string} department - Department name
 * @param {string|array} keywords - Keyword(s) to add
 */
export const addKeyword = (department, keywords) => {
  if (!departmentKeywords[department]) {
    departmentKeywords[department] = [];
  }

  const keywordArray = Array.isArray(keywords) ? keywords : [keywords];
  keywordArray.forEach((kw) => {
    if (!departmentKeywords[department].includes(kw.toLowerCase())) {
      departmentKeywords[department].push(kw.toLowerCase());
    }
  });
};

/**
 * Get all keywords for a department
 * @param {string} department - Department name
 * @returns {array} Array of keywords
 */
export const getKeywords = (department) => {
  return departmentKeywords[department] || [];
};

/**
 * Get all departments
 * @returns {array} Array of department names
 */
export const getAllDepartments = () => {
  return Object.keys(departmentKeywords);
};

export default {
  classifyComplaint,
  addKeyword,
  getKeywords,
  getAllDepartments
};
