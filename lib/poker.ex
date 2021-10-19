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

  # def higher_rank(%{first_player: first_player, second_player: second_player}) do
  #   _higher_rank(player_rank(first_player), player_rank(second_player))
  # end

  # defp _higher_rank(
  #        %Poker{rank: {first_rank, first_rank_point}} = first_player,
  #        %Poker{rank: {second_rank, second_rank_point}} = second_player
  #      ) do
  #   if first_rank_point == second_rank_point do
  #     "===================="
  #     _high_value_from_similar_rank(first_player, second_player)
  #   else
  #     max_point = max(first_rank_point, second_rank_point)

  #     Enum.find([first_player.rank, second_player.rank], fn {_rank, point} ->
  #       point == max_point
  #     end)
  #   end
  # end

  # defp _high_value_from_similar_rank(
  #        %Poker{rank: {first_rank, first_rank_point}} = first_player,
  #        %Poker{rank: {second_rank, second_rank_point}} = second_player
  #      ) do
  #   case first_rank && second_rank do
  #     :high_card ->
  #       [
  #         max_player_value(first_player.values, first_player.player),
  #         max_player_value(second_player.values, second_player.player)
  #       ]
  #       |> Enum.max_by(fn {_value, index, _player} -> index end)
  #       |> Tuple.insert_at(0, :high_card)

  #     :pair ->
  #       if pair_index(first_player.values) == pair_index(second_player.values) do
  #         [
  #           max_player_value(Enum.uniq(first_player.values), first_player.player),
  #           max_player_value(Enum.uniq(second_player.values), second_player.player)
  #         ]
  #         |> Enum.max_by(fn {_value, index, _player} -> index end)
  #         |> Tuple.insert_at(0, :high_card)
  #       end
  #   end
  # end

  def highest_value(player1_values, player2_values, :high_card) do
    Enum.max_by(
      [highest_value(player1_values, :high_card), highest_value(player2_values, :high_card)],
      fn {index, value} -> index end
    )
  end

  def highest_value(player1_values, player2_values, :pair) do
    [{player1_index, _pair_values}] = pair_value(player1_values)
    [{player2_index, _pair_values}] = pair_value(player2_values)

    if player1_index == player2_index do
      player1_highest_card = highest_value(player1_values, :pair)
      player2_highest_card = highest_value(player2_values, :pair)

      Enum.max_by(
        [highest_value(player1_values, :pair), highest_value(player2_values, :pair)],
        fn {index, _value} -> index end
      )
    else
      Enum.max_by(
        pair_value(player1_values) ++ pair_value(player2_values),
        fn {index, _value} -> index end
      )
    end
  end

  def highest_value(player1_values, player2_values, :two_pair) do
    highest_two_pair(player1_values, player2_values, :max_two_pair)
  end

  def highest_two_pair(player1_values, player2_values, :max_two_pair) do
    # max pair value
    {player1_index, _pair_values} = max_pair_value(player1_values, :two_pair)
    {player2_index, _pair_values} = max_pair_value(player2_values, :two_pair)

    if player1_index == player2_index do
      highest_two_pair(player1_values, player2_values, :min_two_pair)
    else
      Enum.max_by(
        [max_pair_value(player1_values, :two_pair), max_pair_value(player2_values, :two_pair)],
        fn {index, _value} -> index end
      )
    end
  end

  def highest_two_pair(player1_values, player2_values, :min_two_pair) do
    # min pair value
    {player1_index, _pair_values} = min_pair_value(player1_values, :two_pair)
    {player2_index, _pair_values} = min_pair_value(player2_values, :two_pair)

    if player1_index == player2_index do
      Enum.max_by(
        [highest_value(player1_values, :pair), highest_value(player2_values, :pair)],
        fn {index, _value} -> index end
      )
    else
      Enum.max_by(
        [min_pair_value(player1_values, :two_pair), min_pair_value(player2_values, :two_pair)],
        fn {index, _value} -> index end
      )
    end
  end

  def max_pair_value(values, :two_pair) do
    values
    |> pair_value()
    |> Enum.max_by(fn {index, value} -> index end)
  end

  def min_pair_value(values, :two_pair) do
    values
    |> pair_value()
    |> Enum.min_by(fn {index, value} -> index end)
  end

  def highest_value(values, :high_card) do
    values
    |> group_card_value_with_index()
    |> Enum.max_by(fn {index, _value} -> index end)
  end

  def highest_value(values, :pair) do
    values
    |> group_card_value_with_index()
    |> Enum.reject(fn {index, value} -> Enum.count(value) == 2 end)
    |> Enum.max_by(fn {index, _value} -> index end)
  end

  def pair_value(values) do
    values
    |> group_card_value_with_index()
    |> Enum.filter(fn {_k, v} -> Enum.count(v) == 2 end)
  end

  def group_card_value_with_index(values) do
    card_values = Enum.with_index(@card_values)

    for value <- values do
      Enum.filter(card_values, fn {v, _i} -> v == value end)
    end
    |> List.flatten()
    |> Enum.group_by(fn {_k, index} -> index end)

    # |> Enum.max_by(fn {_value, index} -> index end)

    # |> Tuple.append(player)
  end

  def player_rank({hand, player}) do
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

  # def pair_index(values) do
  #   card_values = Enum.with_index(@card_values)

  #   {_values, [index | _]} =
  #     for value <- values do
  #       Enum.filter(card_values, fn {v, _i} -> v == value end)
  #     end
  #     |> List.flatten()
  #     |> Enum.sort_by(fn {_value, index} -> index end)
  #     |> Enum.chunk_every(2, 1, :discard)
  #     |> Enum.filter(fn [{_v1, i1}, {_v2, i2}] -> i1 == i2 end)
  #     |> List.flatten()
  #     |> Enum.unzip()

  #   index
  # end

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
