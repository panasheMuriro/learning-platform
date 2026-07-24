import { useQuery } from "@tanstack/react-query";

const API_BASE = "/api";

// ---- Course catalog types ----

export interface CourseSummary {
  id: string;
  slug: string;
  title: string;
  summary: string;
  icon: string;
  version: string;
}

// ---- Outline / module types ----

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

export interface FileEntry {
  name: string;
  path: string;
  isDirectory: boolean;
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

// ---- Fetch helpers ----

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

// ---- Course catalog hooks ----

export function useCourses() {
  return useQuery({
    queryKey: ["courses"],
    queryFn: () => fetchJson<CourseSummary[]>("/courses"),
  });
}

// ---- Course content hooks (course-scoped) ----

export function useCourseOutline(courseId: string) {
  return useQuery({
    queryKey: ["outline", courseId],
    queryFn: () => fetchJson<CourseOutline>(`/courses/${courseId}/outline`),
  });
}

export function useLecture(
  courseId: string,
  moduleId: string,
  lectureId: string,
) {
  return useQuery({
    queryKey: ["lecture", courseId, moduleId, lectureId],
    queryFn: () =>
      fetchJson<Lecture>(
        `/courses/${courseId}/modules/${moduleId}/lectures/${lectureId}`,
      ),
  });
}

export function useQuiz(courseId: string, moduleId: string) {
  return useQuery({
    queryKey: ["quiz", courseId, moduleId],
    queryFn: () =>
      fetchJson<Quiz>(`/courses/${courseId}/modules/${moduleId}/quiz`),
  });
}

export function useLabInstructions(
  courseId: string,
  moduleId: string,
  labId: string,
) {
  return useQuery({
    queryKey: ["lab-instructions", courseId, moduleId, labId],
    queryFn: () =>
      fetchJson<LabInstructions>(
        `/courses/${courseId}/modules/${moduleId}/labs/${labId}`,
      ),
  });
}

export function useProgress(courseId: string) {
  return useQuery({
    queryKey: ["progress", courseId],
    queryFn: () => fetchJson<Progress>(`/courses/${courseId}/progress`),
  });
}

// ---- Mutations (course-scoped) ----

export async function submitQuiz(
  courseId: string,
  moduleId: string,
  answers: Record<string, string | string[]>,
): Promise<{ score: number; passed: boolean }> {
  return postJson(`/courses/${courseId}/modules/${moduleId}/quiz/submit`, {
    answers,
  });
}

export async function checkLab(
  courseId: string,
  moduleId: string,
  labId: string,
): Promise<GradeResult> {
  return postJson(
    `/courses/${courseId}/modules/${moduleId}/labs/${labId}/check`,
    {},
  );
}

// ---- File API (course-agnostic, for lab workspace) ----

export async function listFiles(labPath: string): Promise<FileEntry[]> {
  return fetchJson<FileEntry[]>(`/files?path=${encodeURIComponent(labPath)}`);
}

export async function readFile(filePath: string): Promise<string> {
  const res = await fetch(
    `${API_BASE}/files/content?path=${encodeURIComponent(filePath)}`,
  );
  if (!res.ok) throw new Error(`API ${res.status}`);
  return res.text();
}

export async function writeFile(
  filePath: string,
  content: string,
): Promise<void> {
  await fetch(
    `${API_BASE}/files/content?path=${encodeURIComponent(filePath)}`,
    {
      method: "PUT",
      headers: { "Content-Type": "text/plain" },
      body: content,
    },
  );
}

// ---- Terminal WebSocket (course-agnostic) ----

export function terminalWsUrl(): string {
  const proto = window.location.protocol === "https:" ? "wss:" : "ws:";
  return `${proto}//${window.location.host}/ws/terminal`;
}
