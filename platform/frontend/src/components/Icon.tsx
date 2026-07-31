import {
  Icon as VanillaIcon,
  type IconProps as VanillaIconProps,
} from "@canonical/react-components";
import type { ReactNode } from "react";
import "./Icon.css";

export type IconName =
  | VanillaIconName
  | "arrow-left"
  | "arrow-right"
  | "book"
  | "check"
  | "chevron-down"
  | "chevron-right"
  | "cross"
  | "graduation"
  | "grid"
  | "keyboard"
  | "lightbulb"
  | "lock-open"
  | "warning";

type VanillaIconName =
  | "anchor"
  | "arrow-down"
  | "arrow-left"
  | "arrow-right"
  | "arrow-up"
  | "applications"
  | "book"
  | "chevron-down"
  | "chevron-left"
  | "chevron-right"
  | "chevron-up"
  | "close"
  | "code"
  | "copy"
  | "delete"
  | "error"
  | "expand"
  | "external-link"
  | "help"
  | "information"
  | "keyboard"
  | "lock-unlock"
  | "menu"
  | "minus"
  | "open-terminal"
  | "play"
  | "plus"
  | "question"
  | "search"
  | "share"
  | "success"
  | "topic"
  | "user"
  | "warning";

interface IconProps extends Omit<VanillaIconProps, "name" | "light"> {
  name: IconName;
  size?: number;
  light?: boolean;
}

const ALIAS_MAP: Record<
  Exclude<
    IconName,
    | "anchor"
    | "arrow-down"
    | "arrow-left"
    | "arrow-right"
    | "arrow-up"
    | "applications"
    | "book"
    | "chevron-down"
    | "chevron-left"
    | "chevron-right"
    | "chevron-up"
    | "close"
    | "code"
    | "copy"
    | "delete"
    | "error"
    | "expand"
    | "external-link"
    | "help"
    | "information"
    | "keyboard"
    | "lock-unlock"
    | "menu"
    | "minus"
    | "open-terminal"
    | "play"
    | "plus"
    | "question"
    | "search"
    | "share"
    | "success"
    | "topic"
    | "user"
    | "warning"
  >,
  VanillaIconName
> = {
  check: "success",
  cross: "close",
  graduation: "book",
  grid: "applications",
  lightbulb: "help",
  "lock-open": "lock-unlock",
};

function resolveName(name: IconName): VanillaIconName {
  return (
    (ALIAS_MAP as Record<IconName, VanillaIconName | undefined>)[name] ??
    (name as VanillaIconName)
  );
}

export function Icon({
  name,
  size,
  className,
  light,
  ...props
}: IconProps): ReactNode {
  const vanillaName = resolveName(name);
  const style = size ? { width: size, height: size } : undefined;
  return (
    <VanillaIcon
      name={vanillaName}
      light={light}
      className={`icon ${className ?? ""}`.trim()}
      style={style}
      {...props}
    />
  );
}
