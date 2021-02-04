defmodule Exkubia.Fortune do
  use GenServer
  require Logger

  @default_fortune "No fortune for you 😬"

  def start_link(opts) do
    {config, opts} = Keyword.pop!(opts, :config)

    GenServer.start_link(__MODULE__, config.fortune_path, opts)
  end

  def fortune(pid) do
    GenServer.call(pid, :get_fortune)
  end

  ## GenServer Callbacks

  def init(fortune_path) do
    state = %{
      file_path: Path.absname(fortune_path),
      fortune: @default_fortune
    }

    {:ok, state, {:continue, :init}}
  end

  def handle_continue(:init, state) do
    dir_path = Path.dirname(state.file_path)
    state = %{state | fortune: load_fortune(state.file_path)}

    Logger.info("Starting watch on #{dir_path}")
    :fs.start_link(:fortune_dir_watcher, dir_path)
    :fs.subscribe(:fortune_dir_watcher)

    {:noreply, state}
  end

  def handle_call(:get_fortune, _from, state) do
    {:reply, state.fortune, state}
  end

  def handle_info({_pid, {:fs, :file_event}, {path, events}}, state) do
    Logger.debug("#{inspect(path)}: #{inspect(events)}")

    state =
      if to_string(path) == state.file_path and Exkubia.FileWatchingUtil.modifed?(events) and
           File.exists?(path) do
        Logger.info("Will load new fortune from #{state.file_path}")
        %{state | fortune: load_fortune(state.file_path)}
      else
        state
      end

    {:noreply, state}
  end

  def handle_info(msg, state) do
    Logger.debug("Received unknown message #{inspect(msg)}")

    {:noreply, state}
  end

  defp load_fortune(file_path) do
    if File.exists?(file_path) do
      case File.read(file_path) do
        {:ok, fortune} ->
          fortune

        {:error, _} ->
          Logger.error("Cannot read fortune from #{file_path}")
          @default_fortune
      end
    else
      @default_fortune
    end
  end
end
