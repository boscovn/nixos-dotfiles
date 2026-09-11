{ inputs, pkgs, ... }:
{
  home.packages = [
    inputs.quickshell.packages.${pkgs.system}.default
  ];

  xdg.configFile."quickshell/shell.qml".text = ''
    import Quickshell
    import QtQuick

    ShellRoot {
      PanelWindow {
        anchors {
          top: true
          left: true
          right: true
        }
        height: 30

        Text {
          anchors.centerIn: parent
          text: "hello quickshell"
        }
      }
    }
  '';
}
