import { useCourseOutline } from "@/api/content";
import {
  ApplicationLayout,
  SideNavigation,
  SideNavigationItem,
  SideNavigationLink,
  SideNavigationText,
} from "@canonical/react-components";
import { type ReactNode, useState } from "react";
import { Link, useLocation } from "react-router-dom";
import "./Shell.css";

// Router-aware Link component for SideNavigation.
function RouterLink({
  href,
  children,
  isSelected,
  ...rest
}: {
  href?: string;
  children: ReactNode;
  isSelected?: boolean;
  [key: string]: unknown;
}) {
  return (
    <Link
      to={href ?? "/"}
      aria-current={isSelected ? "page" : undefined}
      {...rest}
    >
      {children}
    </Link>
  );
}

interface ShellProps {
  children: ReactNode;
}

export function Shell({ children }: ShellProps) {
  const { data: outline } = useCourseOutline();
  const location = useLocation();

  const isActive = (url: string) => location.pathname === url;

  // Determine which module is currently active (for auto-expansion)
  const activeModuleId = outline?.modules.find((mod) =>
    location.pathname.startsWith(`/modules/${mod.id}`),
  )?.id;

  // Track manually-expanded modules (in addition to the auto-expanded active one)
  const [expandedModules, setExpandedModules] = useState<Set<string>>(
    new Set(),
  );

  const toggleModule = (moduleId: string) => {
    setExpandedModules((prev) => {
      const next = new Set(prev);
      if (next.has(moduleId)) {
        next.delete(moduleId);
      } else {
        next.add(moduleId);
      }
      return next;
    });
  };

  const isModuleExpanded = (moduleId: string) =>
    moduleId === activeModuleId || expandedModules.has(moduleId);

  return (
    <ApplicationLayout
      dark={false}
      logo={{
        icon: "🎓",
        name: "Juju + Terraform",
        nameAlt: "Course",
        href: "/",
      }}
      sideNavigation={
        <SideNavigation
          dark={false}
          linkComponent={RouterLink}
          ariaLabel="Course navigation"
        >
          {/* Dashboard link — always visible at top */}
          <SideNavigationLink
            label="Dashboard"
            href="/"
            icon="home"
            selected={isActive("/")}
          />

          {/* Each module is a collapsible group */}
          {outline?.modules.map((mod, idx) => {
            const isExpanded = isModuleExpanded(mod.id);
            return (
              <SideNavigationItem
                key={mod.id}
                className={`p-side-navigation__item--expandable ${isExpanded ? "p-side-navigation__item--expanded" : ""}`}
              >
                <button
                  type="button"
                  className="p-side-navigation__button"
                  aria-expanded={isExpanded}
                  onClick={() => toggleModule(mod.id)}
                >
                  <span className="p-side-navigation__label">
                    {idx + 1}. {mod.title}
                  </span>
                </button>
                <ul className="p-side-navigation__list">
                  {mod.lectures.map((lec) => (
                    <li className="p-side-navigation__item" key={lec.id}>
                      <Link
                        to={`/modules/${mod.id}/lectures/${lec.id}`}
                        className="p-side-navigation__link"
                        aria-current={
                          isActive(`/modules/${mod.id}/lectures/${lec.id}`)
                            ? "page"
                            : undefined
                        }
                      >
                        {lec.title}
                      </Link>
                    </li>
                  ))}
                  {mod.quiz && (
                    <li className="p-side-navigation__item">
                      <Link
                        to={`/modules/${mod.id}/quiz`}
                        className="p-side-navigation__link"
                        aria-current={
                          isActive(`/modules/${mod.id}/quiz`)
                            ? "page"
                            : undefined
                        }
                      >
                        📝 Quiz
                      </Link>
                    </li>
                  )}
                  {mod.labs.map((lab) => (
                    <li className="p-side-navigation__item" key={lab.id}>
                      <Link
                        to={`/modules/${mod.id}/labs/${lab.id}`}
                        className="p-side-navigation__link"
                        aria-current={
                          isActive(`/modules/${mod.id}/labs/${lab.id}`)
                            ? "page"
                            : undefined
                        }
                      >
                        🔬 {lab.title}
                      </Link>
                    </li>
                  ))}
                </ul>
              </SideNavigationItem>
            );
          })}

          {!outline && <SideNavigationText>Loading…</SideNavigationText>}
        </SideNavigation>
      }
      mainId="main-content"
    >
      {children}
    </ApplicationLayout>
  );
}
