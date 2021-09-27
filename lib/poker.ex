defmodule Poker do
  defstruct [:rank, :values, :suits, :player, :hand]

  @card_values ["2", "3", "4", "5", "6", "7", "8", "9", "T", "J", "Q", "K", "A"]

  def new(hand \\ []) do
    %__MODULE__{hand: hand}
  end

  def poker_deck({hand, player}) do
    %__MODULE__{
      suits: suits(hand),
      values: values(hand),
      hand: hand,
      player: player
    }
  end

  def rank(%{suits: [suit | _] = suits, values: values} = poker_deck) do
    same_suits? = Enum.all?(suits, fn s -> String.equivalent?(s, suit) end)

    if same_suits? do
      flush_or_straight_flush(values)
    else
      # other ranks
    end
  end

  defp other_ranks(values, rank \\ :none) do
    {values, rank}
    |> rank_as_pair()
    |> rank_as_two_pair()

    # |> rank_as_three_of_a_kind()
    # |> rank_as_straight()
    # |> rank_as_full_house()
    # |> rank_as_four_of_a_kind()
    # |> rank_as_high_card()
  end

  def rank_as_pair({values, rank}) do
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

  def rank_as_two_pair({values, :none}) do
  end

  def rank_as_two_pair(rank_card), do: rank_card

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
