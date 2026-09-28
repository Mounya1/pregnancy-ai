/**
 * Client-safe pregnancy data + helpers. Shared by UI and server functions.
 * No server-only imports here.
 */

export interface WeekData {
  week: number;
  comparison: string;
  lengthCm: number; // crown-to-heel (cm)
  weightG: number; // grams
  note: string;
}

// Curated, week-by-week fetal size + milestone reference.
export const WEEK_DATA: WeekData[] = [
  { week: 1, comparison: "a poppy seed", lengthCm: 0.1, weightG: 0.07, note: "Technically not pregnant yet — counting begins from the first day of your last period." },
  { week: 2, comparison: "a sesame seed", lengthCm: 0.2, weightG: 1, note: "Ovulation occurs; conception is imminent." },
  { week: 3, comparison: "a sesame seed", lengthCm: 0.15, weightG: 0.1, note: "Fertilisation: the zygote begins dividing and travelling toward the uterus." },
  { week: 4, comparison: "a poppy seed", lengthCm: 0.2, weightG: 0.2, note: "The embryo implants in the uterine wall." },
  { week: 5, comparison: "an apple seed", lengthCm: 0.2, weightG: 0.2, note: "The neural tube — future brain and spine — starts forming." },
  { week: 6, comparison: "a lentil", lengthCm: 0.3, weightG: 0.3, note: "The heart begins to beat; limb buds appear." },
  { week: 7, comparison: "a blueberry", lengthCm: 1, weightG: 1, note: "Hands and feet are forming as paddles." },
  { week: 8, comparison: "a raspberry", lengthCm: 1.6, weightG: 1, note: "Fingers and toes are starting to define." },
  { week: 9, comparison: "a cherry", lengthCm: 2.3, weightG: 2, note: "Muscle contractions begin, though not yet felt." },
  { week: 10, comparison: "a kumquat", lengthCm: 3.1, weightG: 4, note: "Vital organs have formed and are starting to function." },
  { week: 11, comparison: "a fig", lengthCm: 4.1, weightG: 7, note: "The baby is now officially a fetus." },
  { week: 12, comparison: "a lime", lengthCm: 5.4, weightG: 14, note: "Reflexes appear; the face has human profile." },
  { week: 13, comparison: "a lemon", lengthCm: 7.4, weightG: 23, note: "Vocal cords form; fingerprints begin to develop." },
  { week: 14, comparison: "a peach", lengthCm: 8.7, weightG: 43, note: "Fine hair (lanugo) covers the body." },
  { week: 15, comparison: "an apple", lengthCm: 10.1, weightG: 70, note: "The baby can sense light through closed eyelids." },
  { week: 16, comparison: "an avocado", lengthCm: 11.6, weightG: 100, note: "Eye movements begin; the heart pumps ~25 quarts/day." },
  { week: 17, comparison: "a pear", lengthCm: 13, weightG: 140, note: "Skeleton hardens from cartilage to bone." },
  { week: 18, comparison: "a bell pepper", lengthCm: 14.2, weightG: 190, note: "The baby can hear and may startle at loud sounds." },
  { week: 19, comparison: "a mango", lengthCm: 15.3, weightG: 240, note: "Vernix, a protective coating, covers the skin." },
  { week: 20, comparison: "a banana", lengthCm: 16.4, weightG: 300, note: "Halfway. You may feel the first movements." },
  { week: 21, comparison: "a carrot", lengthCm: 26.7, weightG: 360, note: "Swallowing increases; taste buds mature." },
  { week: 22, comparison: "a spaghetti squash", lengthCm: 27.8, weightG: 430, note: "Senses of touch and hearing develop further." },
  { week: 23, comparison: "a grapefruit", lengthCm: 28.9, weightG: 501, note: "Lungs prepare to take first breaths." },
  { week: 24, comparison: "an ear of corn", lengthCm: 30, weightG: 600, note: "Surfactant production begins; viability milestone nears." },
  { week: 25, comparison: "a cauliflower", lengthCm: 34.6, weightG: 660, note: "Hair colour and texture are forming." },
  { week: 26, comparison: "a lettuce", lengthCm: 35.6, weightG: 760, note: "Eyes open for the first time." },
  { week: 27, comparison: "a cabbage", lengthCm: 36.6, weightG: 875, note: "Brain activity is rapidly maturing." },
  { week: 28, comparison: "an eggplant", lengthCm: 37.6, weightG: 1005, note: "Third trimester begins; dreaming starts." },
  { week: 29, comparison: "a butternut squash", lengthCm: 38.6, weightG: 1150, note: "Muscles and lungs keep developing." },
  { week: 30, comparison: "a cucumber", lengthCm: 39.9, weightG: 1320, note: "Eyes open and close; brain folds form." },
  { week: 31, comparison: "a coconut", lengthCm: 41.1, weightG: 1500, note: " bones harden; rapid weight gain continues." },
  { week: 32, comparison: "a jicama", lengthCm: 42.4, weightG: 1700, note: "Movements may feel more like rolls than kicks." },
  { week: 33, comparison: "a pineapple", lengthCm: 43.7, weightG: 1920, note: "The skull bones are not yet fused." },
  { week: 34, comparison: "a cantaloupe", lengthCm: 45, weightG: 2150, note: "The nervous system is fully formed." },
  { week: 35, comparison: "a honeydew melon", lengthCm: 46.2, weightG: 2380, note: "Kidneys are fully developed." },
  { week: 36, comparison: "a head of romaine", lengthCm: 47.4, weightG: 2620, note: "The baby may drop into the pelvis." },
  { week: 37, comparison: "a Swiss chard", lengthCm: 48.6, weightG: 2860, note: "Considered early term." },
  { week: 38, comparison: "a leek", lengthCm: 49.8, weightG: 3080, note: "Brain and lungs are nearly ready." },
  { week: 39, comparison: "a mini watermelon", lengthCm: 50.7, weightG: 3290, note: "Full term. Ready to meet the world." },
  { week: 40, comparison: "a small pumpkin", lengthCm: 51.2, weightG: 3460, note: "Your due date — only ~5% arrive on it." },
];

export function clampWeek(week: number): number {
  return Math.max(1, Math.min(40, Math.round(week)));
}

export function getWeekData(week: number): WeekData {
  return WEEK_DATA[clampWeek(week) - 1];
}

export function trimesterOf(week: number): 1 | 2 | 3 {
  const w = clampWeek(week);
  if (w <= 12) return 1;
  if (w <= 26) return 2;
  return 3;
}

export function trimesterName(t: 1 | 2 | 3): string {
  return ["", "First trimester", "Second trimester", "Third trimester"][t];
}

/** Gestational week from an estimated due date (EDD). */
export function weekFromDueDate(dueDate: Date, now: Date = new Date()): number {
  const DAY = 1000 * 60 * 60 * 24;
  const daysUntilDue = Math.ceil((dueDate.getTime() - now.getTime()) / DAY);
  const gestAgeDays = 280 - daysUntilDue; // 280 days = 40 weeks
  return clampWeek(Math.floor(gestAgeDays / 7));
}

export function weeksLeftFromDueDate(dueDate: Date, now: Date = new Date()): number {
  const DAY = 1000 * 60 * 60 * 24;
  return Math.max(0, Math.ceil((dueDate.getTime() - now.getTime()) / (DAY * 7)));
}

export function progressPercent(week: number): number {
  return Math.round((clampWeek(week) / 40) * 100);
}
