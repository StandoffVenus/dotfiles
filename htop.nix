{ config }:

{
  enable = true;
  settings = {
    delay = 12;
    color_scheme = 5;
    cpu_count_from_one = 1;
    show_cpu_usage = 1;
    show_cpu_frequency = 0;
  } // (with config.lib.htop; leftMeters [
    (bar "CPU")
    (bar "LeftCPUs4")
    (bar "RightCPUs4")
    (text "Blank")
    (bar "Memory")
    (bar "Swap")
    (text "Blank")
  ]) // (with config.lib.htop; rightMeters [
    (text "System")
    (text "Battery")
    (text "Blank")
    (text "Blank")
    (text "LoadAverage")
    (text "Tasks")
    (text "Uptime")
  ]);
}
