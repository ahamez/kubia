defmodule Exkubia.Secrets do
  use GenServer
  require Logger

  @secrets_files %{
    "credentials.txt" => :credentials,
    "credentials2.txt" => :credentials2
  }

  def start_link(opts) do
    {config, opts} = Keyword.pop!(opts, :config)

    GenServer.start_link(__MODULE__, config.secrets_dir_path, opts)
  end

  @spec secret(pid() | atom(), atom()) :: {:ok, binary()} | :error
  def secret(pid_or_name, secret) do
    GenServer.call(pid_or_name, {:get_secret, secret})
  end

  ## GenServer Callbacks

  def init(secrets_dir_path) do
    abs_secrets_dir_path = Path.absname(secrets_dir_path)

    state = %{
      dir_path: abs_secrets_dir_path,
      secrets_files: mk_secrets_files(abs_secrets_dir_path),
      secrets: %{}
    }

    {:ok, state, {:continue, :init}}
  end

  def handle_continue(:init, state) do
    state = %{state | secrets: load_all_secrets!(state.secrets_files)}

    Logger.info("Starting watch on #{state.dir_path}")
    :fs.start_link(:secrets_dir_watcher, state.dir_path)
    :fs.subscribe(:secrets_dir_watcher)

    {:noreply, state}
  end

  def handle_call({:get_secret, secret}, _from, state) do
    {:reply, Map.fetch(state.secrets, secret), state}
  end

  def handle_info({_pid, {:fs, :file_event}, {path, events}}, state) do
    path = Path.basename(to_string(path))

    Logger.debug("Secret watcher: #{inspect(path)}: #{inspect(events)}")

    state =
      case state.secrets_files[path] do
        nil ->
          state

        {abs_path, secret_atom} ->
          if File.exists?(abs_path) do
            Logger.info("Reload secret from #{path}")
            %{state | secrets: Map.put(state.secrets, secret_atom, load_secret!(abs_path))}
          else
            state
          end
      end

    {:noreply, state}
  end

  def handle_info(msg, state) do
    Logger.debug("Received unknown message #{inspect(msg)}")

    {:noreply, state}
  end

  defp mk_secrets_files(dir_path) do
    for {file_name, secret_atom} <- @secrets_files, into: %{} do
      {file_name, {Path.join([dir_path, file_name]), secret_atom}}
    end
  end

  defp load_all_secrets!(secrets_files) do
    for {_file_name, {abs_file_path, secret_atom}} <- secrets_files, into: %{} do
      {secret_atom, load_secret!(abs_file_path)}
    end
  end

  defp load_secret!(file_path) do
    File.read!(file_path)
  end
end
