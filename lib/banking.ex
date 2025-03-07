defmodule Banking do
  use Application


  def start(_type, _args) do
    ManagerSup.start_link()
  end
end
