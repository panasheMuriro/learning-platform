import { markLectureComplete, useCourseOutline, useLecture } from "@/api/content";
import { BottomNav } from "@/components/BottomNav";
import { useQueryClient } from "@tanstack/react-query";
import { useEffect, useRef } from "react";
import { useParams } from "react-router-dom";
import { LectureQuiz } from "./LectureQuiz";
import { LectureViewer } from "./LectureViewer";

export function LecturePage() {
  const { courseId = "", moduleId = "", lectureId = "" } = useParams();
  const queryClient = useQueryClient();
  const {
    data: lecture,
    isLoading,
    error,
  } = useLecture(courseId, moduleId, lectureId);
  const { data: outline } = useCourseOutline(courseId);

  // Track which lecture we've already marked complete to avoid duplicate
  // POSTs when the effect re-runs (e.g. after a query cache update).
  const markedRef = useRef<string>("");

  useEffect(() => {
    if (!courseId || !moduleId || !lectureId) return;
    const key = `${courseId}/${moduleId}/${lectureId}`;
    if (markedRef.current === key) return;
    markedRef.current = key;

    let cancelled = false;
    (async () => {
      try {
        const updated = await markLectureComplete(
          courseId,
          moduleId,
          lectureId,
        );
        if (cancelled) return;
        // Update the progress cache so the sidebar checkmarks update live.
        queryClient.setQueryData(["progress", courseId], updated);
      } catch (err) {
        // Non-fatal: the lecture still renders; progress will retry next visit.
        console.error("failed to mark lecture complete:", err);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [courseId, moduleId, lectureId, queryClient]);

  if (isLoading) return <div className="course-content">Loading lecture…</div>;
  if (error || !lecture)
    return <div className="course-content">Failed to load lecture.</div>;

  return (
    <div className="course-content">
      <LectureViewer markdown={lecture.markdown} />
      {lecture.questions && lecture.questions.length > 0 && (
        <LectureQuiz
          courseId={courseId}
          moduleId={moduleId}
          lectureId={lectureId}
          questions={lecture.questions}
        />
      )}
      {outline && (
        <BottomNav
          courseId={courseId}
          moduleId={moduleId}
          currentItemType="lecture"
          currentItemId={lectureId}
          outline={outline}
        />
      )}
    </div>
  );
}
