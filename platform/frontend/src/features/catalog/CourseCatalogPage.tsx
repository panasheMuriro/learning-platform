import { useCourses } from "@/api/content";
import { Icon, type IconName } from "@/components/Icon";
import { Card } from "@canonical/react-components";
import { Link } from "react-router-dom";
import "./CourseCatalogPage.css";

export function CourseCatalogPage() {
  const { data: courses, isLoading, error } = useCourses();

  if (isLoading) {
    return (
      <div className="course-content">
        <div className="catalog__loading">
          <Icon name="spinner" className="catalog__spinner" size={24} />
          <span>Loading course catalog...</span>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="course-content">
        <div className="p-notification--negative">
          <div className="p-notification__content">
            <h5 className="p-notification__title">Failed to load courses</h5>
            <p className="p-notification__message">
              Unable to connect to the course API service. Please verify your connection.
            </p>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="catalog">
      <div className="catalog__hero">
        <div className="catalog__hero-header">
          <div className="catalog__badge">Canonical Learning Platform</div>
          <h1 className="catalog__title">Interactive Engineering Courses</h1>
          <p className="catalog__subtitle">
            Master Canonical technologies with live interactive environments, verified terminal tasks, and self-paced assessments.
          </p>
        </div>
      </div>

      <div className="catalog__section">
        <div className="catalog__section-header">
          <h2 className="catalog__section-title">Available Curricula</h2>
          <span className="catalog__count">{courses?.length ?? 0} Track{courses?.length === 1 ? "" : "s"}</span>
        </div>

        <div className="catalog__grid">
          {courses?.map((course) => (
            <Link
              key={course.id}
              to={`/courses/${course.slug}`}
              className="catalog__card-link"
            >
              <Card className="catalog__card">
                <div className="catalog__card-header">
                  <div className="catalog__card-icon-box">
                    <Icon
                      name={(course.icon as IconName) || "book"}
                      className="catalog__card-icon"
                      size={28}
                    />
                  </div>
                  {course.version && (
                    <span className="catalog__card-version">v{course.version}</span>
                  )}
                </div>
                
                <h3 className="catalog__card-title">{course.title}</h3>
                <p className="catalog__card-summary">{course.summary}</p>
                
                <div className="catalog__card-footer">
                  <span className="catalog__card-action">
                    Explore Course <Icon name="arrow-right" size={14} />
                  </span>
                </div>
              </Card>
            </Link>
          ))}
          {courses?.length === 0 && (
            <div className="catalog__empty">
              <Icon name="topic" size={36} />
              <p>No courses available in this catalog yet.</p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
