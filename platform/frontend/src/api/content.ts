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
  workspace: "code-server" | "terminal";
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
  questions?: QuizQuestion[];
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

export interface LabTask {
  id: string;
  title: string;
  instructions: string;
  hints?: string[];
  solution?: string;
  check: string;
  workspace?: Record<string, string>;
}

export interface LabInstructions {
  id: string;
  title: string;
  markdown: string;
  tasks?: LabTask[];
}

export interface FileEntry {
  name: string;
  path: string;
  isDirectory: boolean;
}

export interface TaskResult {
  id: string;
  name: string;
  passed: boolean;
  message: string;
}

export interface GradeResult {
  labId: string;
  passed: boolean;
  tasks: TaskResult[];
}

export interface Progress {
  modules: {
    moduleId: string;
    lecturesCompleted: string[];
    quizPassed: boolean;
    quizScore: number | null;
    labsCompleted: string[];
    tasksCompleted?: Record<string, string[]>;
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

/** Fetch a single course's metadata by filtering the course list. */
export function useCourse(courseId: string) {
  const { data, isLoading, error } = useCourses();
  const course = data?.find((c) => c.id === courseId || c.slug === courseId);
  return { data: course, isLoading, error };
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

export async function markLectureComplete(
  courseId: string,
  moduleId: string,
  lectureId: string,
): Promise<Progress> {
  return postJson<Progress>(
    `/courses/${courseId}/modules/${moduleId}/lectures/${lectureId}/complete`,
    {},
  );
}

export async function unmarkLecture(
  courseId: string,
  moduleId: string,
  lectureId: string,
): Promise<Progress> {
  const res = await fetch(
    `${API_BASE}/courses/${courseId}/modules/${moduleId}/lectures/${lectureId}/complete`,
    { method: "DELETE" },
  );
  if (!res.ok) throw new Error(`API ${res.status}`);
  return res.json() as Promise<Progress>;
}

export async function unmarkLab(
  courseId: string,
  moduleId: string,
  labId: string,
): Promise<Progress> {
  const res = await fetch(
    `${API_BASE}/courses/${courseId}/modules/${moduleId}/labs/${labId}/complete`,
    { method: "DELETE" },
  );
  if (!res.ok) throw new Error(`API ${res.status}`);
  return res.json() as Promise<Progress>;
}

export async function unmarkQuiz(
  courseId: string,
  moduleId: string,
): Promise<Progress> {
  const res = await fetch(
    `${API_BASE}/courses/${courseId}/modules/${moduleId}/quiz/complete`,
    { method: "DELETE" },
  );
  if (!res.ok) throw new Error(`API ${res.status}`);
  return res.json() as Promise<Progress>;
}

export async function resetCourseProgress(courseId: string): Promise<Progress> {
  const res = await fetch(`${API_BASE}/courses/${courseId}/progress`, {
    method: "DELETE",
  });
  if (!res.ok) throw new Error(`API ${res.status}`);
  return res.json() as Promise<Progress>;
}

export async function submitQuiz(
  courseId: string,
  moduleId: string,
  answers: Record<string, string | string[]>,
): Promise<{ score: number; passed: boolean }> {
  return postJson(`/courses/${courseId}/modules/${moduleId}/quiz/submit`, {
    answers,
  });
}

export async function submitLectureQuiz(
  courseId: string,
  moduleId: string,
  lectureId: string,
  answers: Record<string, string | string[]>,
): Promise<{ score: number; passed: boolean }> {
  return postJson(
    `/courses/${courseId}/modules/${moduleId}/lectures/${lectureId}/quiz/submit`,
    { answers },
  );
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

export async function checkTask(
  courseId: string,
  moduleId: string,
  labId: string,
  taskId: string,
): Promise<GradeResult> {
  return postJson(
    `/courses/${courseId}/modules/${moduleId}/labs/${labId}/tasks/${taskId}/check`,
    {},
  );
}

export async function openLab(
  courseId: string,
  moduleId: string,
  labId: string,
): Promise<{ labPath: string }> {
  return postJson(
    `/courses/${courseId}/modules/${moduleId}/labs/${labId}/open`,
    {},
  );
}

export async function applyTaskWorkspace(
  courseId: string,
  moduleId: string,
  labId: string,
  taskId: string,
): Promise<{ ok: boolean }> {
  return postJson(
    `/courses/${courseId}/modules/${moduleId}/labs/${labId}/tasks/${taskId}/workspace`,
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
