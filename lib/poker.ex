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

  def higher_rank_player(%{first_player: first_player, second_player: second_player}) do
    _higher_rank_player(player_rank(first_player), player_rank(second_player))
  end

  def new(hand, player) do
    %__MODULE__{
      suits: suits(hand),
      values: values(hand),
      hand: hand,
      player: player,
      rank: :none
    }
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

  defp rank_points(%{rank: rank} = poker_deck) do
    rank =
      @rank
      |> Enum.zip(1..9)
      |> Enum.find(fn {rank_name, _point} -> rank_name == rank end)

    %{poker_deck | rank: rank}
  end

  def _higher_rank_player(
        %Poker{rank: {first_rank, first_rank_point}} = first_player,
        %Poker{rank: {second_rank, second_rank_point}} = second_player
      ) do
    if first_rank_point == second_rank_point do
      game_result(first_player, second_player)
    else
      max_point = max(first_rank_point, second_rank_point)
      player1_rank = first_player.rank |> Tuple.append(first_player.player)
      player2_rank = second_player.rank |> Tuple.append(second_player.player)

      {rank, value, player} =
        Enum.find([player1_rank, player2_rank], fn {_rank, point, _player} ->
          point == max_point
        end)

      "#{player} wins - #{rank}: #{value}"
    end
  end

  def game_result(
        %Poker{rank: {first_rank, first_rank_point}} = first,
        %Poker{rank: {second_rank, second_rank_point}} = second
      ) do
    case first_rank && second_rank do
      :high_card ->
        {first.values, first.player}
        |> highest_value({second.values, second.player}, :high_card_or_flush_or_straight)
        |> game_result(:high_card)

      :straight_flush ->
        {first.values, first.player}
        |> highest_value({second.values, second.player}, :high_card_or_flush_or_straight)
        |> game_result(:straight_flush)

      :flush ->
        {first.values, first.player}
        |> highest_value({second.values, second.player}, :high_card_or_flush_or_straight)
        |> game_result(:flush)

      :straight ->
        {first.values, first.player}
        |> highest_value({second.values, second.player}, :high_card_or_flush_or_straight)
        |> game_result(:straight)

      :three_of_a_kind ->
        {first.values, first.player}
        |> highest_value({second.values, second.player}, :three_of_a_kind_or_full_house)
        |> game_result(:three_of_a_kind)

      :full_house ->
        {first.values, first.player}
        |> highest_value({second.values, second.player}, :three_of_a_kind_or_full_house)
        |> game_result(:full_house)

      :four_of_a_kind ->
        {first.values, first.player}
        |> highest_value({second.values, second.player}, :four_of_a_kind)
        |> game_result(:four_of_a_kind)

      :two_pair ->
        {first.values, first.player}
        |> highest_value({second.values, second.player}, :two_pair)
        |> game_result(:two_pair)

      :pair ->
        {first.values, first.player}
        |> highest_value({second.values, second.player}, :pair)
        |> game_result(:pair)
    end
  end

  def game_result({_index, [value], player}, rank) do
    "#{player} wins - #{rank}: #{elem(value, 0)}"
  end

  def highest_value(
        {player1_values, player1},
        {player2_values, player2},
        :high_card_or_flush_or_straight
      ) do
    player1_rank = player1_values |> highest_value(:high_card) |> Tuple.append(player1)
    player2_rank = player2_values |> highest_value(:high_card) |> Tuple.append(player2)

    Enum.max_by(
      [player1_rank, player2_rank],
      fn {index, value, player} -> index end
    )
  end

  def highest_value(
        {player1_values, player1},
        {player2_values, player2},
        :three_of_a_kind_or_full_house
      ) do
    [player1_rank] = tripple_value(player1_values)
    [player2_rank] = tripple_value(player2_values)

    player1_rank = player1_rank |> Tuple.append(player1)
    player2_rank = player2_rank |> Tuple.append(player2)

    Enum.max_by(
      [player1_rank, player2_rank],
      fn {index, value, player} -> index end
    )
  end

  def highest_value({player1_values, player1}, {player2_values, player2}, :four_of_a_kind) do
    [player1_rank] = quad_value(player1_values)
    [player2_rank] = quad_value(player2_values)

    player1_rank = player1_rank |> Tuple.append(player1)
    player2_rank = player2_rank |> Tuple.append(player2)

    Enum.max_by(
      [player1_rank, player2_rank],
      fn {index, _value, _player} -> index end
    )
  end

  def highest_value({player1_values, player1}, {player2_values, player2}, :pair) do
    [{player1_index, _pair_values}] = pair_value(player1_values)
    [{player2_index, _pair_values}] = pair_value(player2_values)

    if player1_index == player2_index do
      player1_rank = player1_values |> highest_value(:pair) |> Tuple.append(player1)
      player2_rank = player2_values |> highest_value(:pair) |> Tuple.append(player2)

      Enum.max_by(
        [player1_rank, player2_rank],
        fn {index, _value, _player} -> index end
      )
    else
      [player1_rank] = pair_value(player1_values)
      [player2_rank] = pair_value(player2_values)

      player1_rank = player1_rank |> Tuple.append(player1)
      player2_rank = player2_rank |> Tuple.append(player2)

      Enum.max_by(
        [player1_rank, player2_rank],
        fn {index, _value, _player} -> index end
      )
    end
  end

  def highest_value(player1_values, player2_values, :two_pair) do
    highest_two_pair(player1_values, player2_values, :max_two_pair)
  end

  def highest_two_pair({player1_values, player1}, {player2_values, player2}, :max_two_pair) do
    # max pair value
    {player1_index, _pair_values} = max_pair_value(player1_values, :two_pair)
    {player2_index, _pair_values} = max_pair_value(player2_values, :two_pair)

    if player1_index == player2_index do
      highest_two_pair(player1_values, player2_values, :min_two_pair)
    else
      player1_rank = player1_values |> max_pair_value(:two_pair) |> Tuple.append(player1)
      player2_rank = player2_values |> max_pair_value(:two_pair) |> Tuple.append(player2)

      Enum.max_by(
        [player1_rank, player2_rank],
        fn {index, _value, _player} -> index end
      )
    end
  end

  def highest_two_pair({player1_values, player1}, {player2_values, player2}, :min_two_pair) do
    # min pair value
    {player1_index, _pair_values} = min_pair_value(player1_values, :two_pair)
    {player2_index, _pair_values} = min_pair_value(player2_values, :two_pair)

    if player1_index == player2_index do
      player1_rank = player1_values |> highest_value(:pair) |> Tuple.append(player1)
      player2_rank = player2_values |> highest_value(:pair) |> Tuple.append(player2)

      Enum.max_by(
        [player1_rank, player2_rank],
        fn {index, _value, _player} -> index end
      )
    else
      player1_rank = player1_values |> min_pair_value(:two_pair) |> Tuple.append(player1)
      player2_rank = player2_values |> min_pair_value(:two_pair) |> Tuple.append(player2)

      Enum.max_by(
        [player1_rank, player2_rank],
        fn {index, _value, _player} -> index end
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

  def tripple_value(values) do
    values
    |> group_card_value_with_index()
    |> Enum.filter(fn {_k, v} -> Enum.count(v) == 3 end)
  end

  def quad_value(values) do
    values
    |> group_card_value_with_index()
    |> Enum.filter(fn {_k, v} -> Enum.count(v) == 4 end)
  end

  def group_card_value_with_index(values) do
    card_values = Enum.with_index(@card_values)

    for value <- values do
      Enum.filter(card_values, fn {v, _i} -> v == value end)
    end
    |> List.flatten()
    |> Enum.group_by(fn {_k, index} -> index end)
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
