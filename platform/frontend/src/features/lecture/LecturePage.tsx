import { useLecture } from "@/api/content";
import { useParams } from "react-router-dom";
import { LectureViewer } from "./LectureViewer";

export function LecturePage() {
  const { moduleId = "", lectureId = "" } = useParams();
  const { data: lecture, isLoading, error } = useLecture(moduleId, lectureId);

  if (isLoading) return <div className="course-content">Loading lecture…</div>;
  if (error || !lecture)
    return <div className="course-content">Failed to load lecture.</div>;

  return (
    <div className="course-content">
      <LectureViewer markdown={lecture.markdown} />
    </div>
  );
}
