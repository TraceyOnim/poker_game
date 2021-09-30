defmodule Poker do
  defstruct [:rank, :values, :suits, :player, :hand]

  @card_values ["2", "3", "4", "5", "6", "7", "8", "9", "T", "J", "Q", "K", "A"]
  @rank [
    :high_card,
    :pair,
    :two_pair,
    :three_of_a_kind,
    :straight,
    :flush,
    :full_house,
    :four_of_a_kind,
    :straight_flush
  ]

  def new(hand, player) do
    %__MODULE__{
      suits: suits(hand),
      values: values(hand),
      hand: hand,
      player: player,
      rank: :none
    }
  end

  # def higher_rank(%{black: black_hand, white: white_hand}) do
  # end

  def player_rank(hand, player) do
    hand
    |> new(player)
    |> rank()
    |> rank_points()
  end

  def rank(%{suits: [suit | _] = suits, values: values} = poker_deck) do
    same_suits? = Enum.all?(suits, fn s -> String.equivalent?(s, suit) end)

    rank =
      if same_suits? do
        flush_or_straight_flush(values)
      else
        rank(values)
      end

    %{poker_deck | rank: rank}
  end

  def rank(values, rank \\ :none) do
    {_values, rank} =
      {values, rank}
      |> rank_as_full_house()
      |> rank_as_pair()
      |> rank_as_two_pair()
      |> rank_as_three_of_a_kind()
      |> rank_as_straight()
      |> rank_as_four_of_a_kind()

    case rank do
      :none -> :high_card
      rank -> rank
    end
  end

  defp rank_as_full_house({values, :none = rank}) do
    frequencies =
      values
      |> Enum.frequencies()
      |> Enum.map(fn {_value, frequency} -> frequency end)
      |> Enum.sort()

    if frequencies == [2, 3] do
      {values, :full_house}
    else
      {values, rank}
    end
  end

  defp rank_as_full_house(rank_card), do: rank_card

  defp rank_as_pair({values, :none = rank}) do
    count =
      values
      |> Enum.frequencies()
      |> Enum.filter(fn {_value, frequency} -> frequency == 2 end)
      |> Enum.count()

    if count == 1 do
      {values, :pair}
    else
      {values, rank}
    end
  end

  defp rank_as_pair(rank_card), do: rank_card

  defp rank_as_two_pair({values, :none = rank}) do
    count =
      values
      |> Enum.frequencies()
      |> Enum.filter(fn {_value, frequency} -> frequency == 2 end)
      |> Enum.count()

    if count == 2 do
      {values, :two_pair}
    else
      {values, rank}
    end
  end

  defp rank_as_two_pair(rank_card), do: rank_card

  defp rank_as_three_of_a_kind({values, :none = rank}) do
    count =
      values
      |> Enum.frequencies()
      |> Enum.filter(fn {_value, frequency} -> frequency == 3 end)
      |> Enum.count()

    if count == 1 do
      {values, :three_of_a_kind}
    else
      {values, rank}
    end
  end

  defp rank_as_three_of_a_kind(rank_card), do: rank_card

  defp rank_as_straight({values, :none = rank}) do
    if consecutive_values?(values) do
      {values, :straight}
    else
      {values, rank}
    end
  end

  defp rank_as_straight(rank_card), do: rank_card

  defp rank_as_four_of_a_kind({values, :none = rank}) do
    frequencies =
      values
      |> Enum.frequencies()
      |> Enum.map(fn {_value, frequency} -> frequency end)
      |> Enum.sort()

    if frequencies == [1, 4] do
      {values, :four_of_a_kind}
    else
      {values, rank}
    end
  end

  defp rank_as_four_of_a_kind(rank_card), do: rank_card

  defp flush_or_straight_flush(values) do
    if consecutive_values?(values) do
      :straight_flush
    else
      :flush
    end
  end

  defp consecutive_values?(values) do
    @card_values
    |> Enum.with_index()
    |> Enum.reduce([], fn {value, index}, acc ->
      if value in values, do: acc ++ [index], else: acc
    end)
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.all?(fn [x, y] -> y == x + 1 end)
  end

  defp rank_points(%{rank: rank} = poker_deck) do
    rank =
      @rank
      |> Enum.zip(1..9)
      |> Enum.find(fn {rank_name, _point} -> rank_name == rank end)

    %{poker_deck | rank: rank}
  end

  defp suits(hand) do
    for h <- hand do
      {_value, suit} = String.split_at(h, 1)
      suit
    end
  end

  defp values(hand) do
    for h <- hand do
      {value, _suit} = String.split_at(h, 1)
      value
    end
  end
end
