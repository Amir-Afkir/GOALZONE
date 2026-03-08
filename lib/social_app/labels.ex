defmodule SocialApp.Labels do
  @moduledoc """
  Helpers de libelles pour l'UI TTC-inspired.
  """

  @role_values [:player, :coach, :agent, :scout, :club]
  @level_values [:espoir, :confirme, :elite]
  @availability_values [:open, :monitoring, :closed]
  @stage_values [:sourced, :qualified, :contacted, :trial, :offer, :signed, :rejected]

  def role_values, do: @role_values
  def level_values, do: @level_values
  def availability_values, do: @availability_values
  def stage_values, do: @stage_values

  def role_label(:player), do: "Joueur"
  def role_label(:coach), do: "Coach"
  def role_label(:agent), do: "Agent"
  def role_label(:scout), do: "Scout"
  def role_label(:club), do: "Club"
  def role_label(role) when is_binary(role), do: role |> to_atom(@role_values) |> role_label()
  def role_label(_), do: "Membre"

  def level_label(:espoir), do: "Espoir"
  def level_label(:confirme), do: "Confirme"
  def level_label(:elite), do: "Elite"

  def level_label(level) when is_binary(level),
    do: level |> to_atom(@level_values) |> level_label()

  def level_label(_), do: "Niveau non renseigne"

  def availability_label(:open), do: "Disponible"
  def availability_label(:monitoring), do: "En veille"
  def availability_label(:closed), do: "Indisponible"

  def availability_label(value) when is_binary(value) do
    value |> to_atom(@availability_values) |> availability_label()
  end

  def availability_label(_), do: "Non precise"

  def stage_label(:sourced), do: "Sourcing"
  def stage_label(:qualified), do: "Qualifie"
  def stage_label(:contacted), do: "Contacte"
  def stage_label(:trial), do: "Essai"
  def stage_label(:offer), do: "Offre"
  def stage_label(:signed), do: "Signe"
  def stage_label(:rejected), do: "Refuse"

  def stage_label(value) when is_binary(value) do
    value |> to_atom(@stage_values) |> stage_label()
  end

  def stage_label(_), do: "Sourcing"

  def parse_role(value), do: to_atom(value, @role_values)
  def parse_level(value), do: to_atom(value, @level_values)
  def parse_availability(value), do: to_atom(value, @availability_values)

  defp to_atom(value, allowed) when is_atom(value) do
    if value in allowed, do: value, else: nil
  end

  defp to_atom(value, allowed) when is_binary(value) do
    if value in Enum.map(allowed, &Atom.to_string/1), do: String.to_atom(value), else: nil
  end

  defp to_atom(_, _), do: nil
end
