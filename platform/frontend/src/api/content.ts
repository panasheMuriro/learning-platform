import { useQuery } from "@tanstack/react-query";

const API_BASE = "/api";

// ---- Types ----

export interface LectureRef {
  id: string;
  title: string;
}

export interface LabRef {
  id: string;
  title: string;
}

export interface ModuleOutline {
  id: string;
  title: string;
  lectures: LectureRef[];
  labs: LabRef[];
  quiz?: { id: string };
}

export interface CourseOutline {
  title: string;
  modules: ModuleOutline[];
}

export interface Lecture {
  id: string;
  title: string;
  markdown: string;
}

export interface QuizQuestion {
  id: string;
  prompt: string;
  type: "single-choice" | "multi-choice" | "text-answer";
  options?: string[];
  answer: string | string[];
  explanation?: string;
}

export interface Quiz {
  moduleId: string;
  questions: QuizQuestion[];
}

export interface LabInstructions {
  id: string;
  title: string;
  markdown: string;
}

export interface GradeResult {
  labId: string;
  passed: boolean;
  tasks: { id: string; name: string; passed: boolean; message: string }[];
}

export interface Progress {
  modules: {
    moduleId: string;
    lecturesCompleted: string[];
    quizPassed: boolean;
    quizScore: number | null;
    labsCompleted: string[];
  }[];
}

// ---- API functions ----

async function fetchJson<T>(path: string): Promise<T> {
  const res = await fetch(`${API_BASE}${path}`);
  if (!res.ok) throw new Error(`API ${res.status}: ${path}`);
  return res.json() as Promise<T>;
}

async function postJson<T>(path: string, body: unknown): Promise<T> {
  const res = await fetch(`${API_BASE}${path}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
  if (!res.ok) throw new Error(`API ${res.status}: ${path}`);
  return res.json() as Promise<T>;
}

// ---- Hooks ----

export function useCourseOutline() {
  return useQuery({
    queryKey: ["outline"],
    queryFn: () => fetchJson<CourseOutline>("/outline"),
  });
}

export function useLecture(moduleId: string, lectureId: string) {
  return useQuery({
    queryKey: ["lecture", moduleId, lectureId],
    queryFn: () =>
      fetchJson<Lecture>(`/modules/${moduleId}/lectures/${lectureId}`),
  });
}

export function useQuiz(moduleId: string) {
  return useQuery({
    queryKey: ["quiz", moduleId],
    queryFn: () => fetchJson<Quiz>(`/modules/${moduleId}/quiz`),
  });
}

export function useLabInstructions(moduleId: string, labId: string) {
  return useQuery({
    queryKey: ["lab-instructions", moduleId, labId],
    queryFn: () =>
      fetchJson<LabInstructions>(`/modules/${moduleId}/labs/${labId}`),
  });
}

export function useProgress() {
  return useQuery({
    queryKey: ["progress"],
    queryFn: () => fetchJson<Progress>("/progress"),
  });
}

// ---- Mutations ----

export async function submitQuiz(
  moduleId: string,
  answers: Record<string, string | string[]>,
): Promise<{ score: number; passed: boolean }> {
  return postJson(`/modules/${moduleId}/quiz/submit`, { answers });
}

export async function checkLab(
  moduleId: string,
  labId: string,
): Promise<GradeResult> {
  return postJson(`/modules/${moduleId}/labs/${labId}/check`, {});
}

// Note: File API and Terminal WebSocket are no longer used from the frontend.
// The lab workspace now uses code-server (VS Code in the browser) which handles
// file editing and terminal directly. The backend still has the file API and
// PTY service for the grading endpoint (check.sh runs inside the lab dir).
