defmodule SocialAppWeb.FeedLive.Params do
  @moduledoc false

  @post_format_values ~w(post photo video article)
  @intention_values ~w(entertainment showcase recruitment)
  @feed_tabs [
    %{value: "for_you", label: "Pour vous"},
    %{value: "following", label: "Abonnes"},
    %{value: "talents", label: "Talents"},
    %{value: "opportunities", label: "Opportunites"}
  ]
  @feed_sorts [
    %{value: "relevance", label: "Pertinence"},
    %{value: "recent", label: "Recent"}
  ]
  @source_type_values %{
    "highlight_video" => :highlight_video,
    "full_match_video" => :full_match_video,
    "live_observation" => :live_observation,
    "stat_report" => :stat_report
  }

  @feed_tab_values Enum.map(@feed_tabs, & &1.value)
  @feed_sort_values Enum.map(@feed_sorts, & &1.value)

  def feed_tabs, do: @feed_tabs
  def feed_sorts, do: @feed_sorts

  def parse_feed_tab(value) when value in @feed_tab_values, do: value
  def parse_feed_tab(_), do: "for_you"

  def parse_feed_sort(value) when value in @feed_sort_values, do: value
  def parse_feed_sort(_), do: "relevance"

  def parse_post_format(value) when value in @post_format_values, do: String.to_atom(value)
  def parse_post_format(_), do: :post

  def parse_intention(value) when value in @intention_values, do: String.to_atom(value)
  def parse_intention(_), do: :entertainment

  def parse_id(nil), do: nil
  def parse_id(""), do: nil
  def parse_id(value) when is_integer(value) and value > 0, do: value
  def parse_id(value) when is_integer(value), do: nil

  def parse_id(value) when is_binary(value) do
    case Integer.parse(value) do
      {parsed, ""} when parsed > 0 -> parsed
      _ -> nil
    end
  end

  def parse_id(_), do: nil

  def structured_intention?(value) when is_binary(value), do: value in ~w(showcase recruitment)
  def structured_intention?(value), do: value in [:showcase, :recruitment]

  def default_post_form_values do
    %{
      "content" => "",
      "post_format" => "post",
      "intention" => "entertainment",
      "media_url" => "",
      "competition" => "",
      "opponent" => "",
      "match_minute" => "",
      "source_type" => "highlight_video",
      "confidence_score" => ""
    }
  end

  def normalize_post_form_values(params) do
    params
    |> Kernel.||(%{})
    |> Map.new()
    |> then(&Map.merge(default_post_form_values(), &1))
  end

  def override_format(values, nil), do: values

  def override_format(values, format) do
    Map.put(values, "post_format", format |> parse_post_format() |> Atom.to_string())
  end

  def override_intention(values, nil), do: values

  def override_intention(values, intention) do
    Map.put(values, "intention", intention |> parse_intention() |> Atom.to_string())
  end

  def build_post_attrs(params) do
    intention = parse_intention(params["intention"])
    structured = structured_intention?(intention)

    %{
      content: String.trim(params["content"] || ""),
      post_format: parse_post_format(params["post_format"]),
      intention: intention,
      media_url: blank_to_nil(params["media_url"]),
      competition: if(structured, do: blank_to_nil(params["competition"]), else: nil),
      opponent: if(structured, do: blank_to_nil(params["opponent"]), else: nil),
      match_minute: if(structured, do: parse_optional_int(params["match_minute"]), else: nil),
      source_type: if(structured, do: parse_source_type(params["source_type"]), else: :unknown),
      confidence_score:
        if(structured, do: parse_optional_int(params["confidence_score"]), else: nil),
      verification_status: :self_declared
    }
  end

  def post_format_options do
    [
      %{value: "post", label: "Post"},
      %{value: "photo", label: "Photo"},
      %{value: "video", label: "Video"},
      %{value: "article", label: "Article"}
    ]
  end

  def intention_options do
    [
      %{value: "entertainment", label: "Divertir"},
      %{value: "showcase", label: "Me faire reperer"},
      %{value: "recruitment", label: "Recruter / scouter"}
    ]
  end

  def composer_placeholder("article", _),
    do: "Partage une analyse, une histoire de match ou ton point de vue football..."

  def composer_placeholder("photo", _),
    do: "Decris la photo: contexte, energie du moment, ce qu'on doit regarder..."

  def composer_placeholder("video", "showcase"),
    do: "Explique l'action: contexte, decision prise, impact sur le jeu..."

  def composer_placeholder("video", "recruitment"),
    do: "Explique ce que le recruteur doit observer sur cette video..."

  def composer_placeholder(_, "recruitment"),
    do: "Decris le profil recherche ou l'opportunite (poste, niveau, criteres)..."

  def composer_placeholder(_, "showcase"),
    do: "Decris l'action ou la performance que tu veux mettre en avant..."

  def composer_placeholder(_, _),
    do: "Partage un moment foot marquant pour la communaute..."

  defp parse_source_type(value), do: Map.get(@source_type_values, value, :unknown)

  defp parse_optional_int(nil), do: nil
  defp parse_optional_int(""), do: nil

  defp parse_optional_int(value) when is_integer(value), do: value

  defp parse_optional_int(value) when is_binary(value) do
    case Integer.parse(value) do
      {parsed, ""} -> parsed
      _ -> nil
    end
  end

  defp parse_optional_int(_), do: nil

  defp blank_to_nil(nil), do: nil

  defp blank_to_nil(value) when is_binary(value) do
    value = String.trim(value)
    if value == "", do: nil, else: value
  end

  defp blank_to_nil(_), do: nil
end
