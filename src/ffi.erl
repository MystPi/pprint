-module(ffi).
-export([decode_nil/1, decode_tuple/1, decode_custom_type/1]).

-define(is_digit_char(X), (X > 47 andalso X < 58)).
-define(is_lowercase_char(X), (X > 96 andalso X < 123)).
-define(is_underscore_char(X), (X == 95)).

decode_nil(X) ->
    case X of
        nil -> {ok, nil};
        _ -> decode_error("Nil", X)
    end.

decode_tuple(X) ->
    case X of
        Tuple when is_tuple(Tuple) -> {ok, tuple_to_list(Tuple)};
        _ -> decode_error("Tuple", X)
    end.

decode_custom_type(X) ->
    case X of
        Tuple when is_tuple(Tuple) ->
            case tuple_to_list(Tuple) of
                [Atom | Elements] when is_atom(Atom) ->
                    case inspect_maybe_gleam_atom(erlang:atom_to_binary(Atom), none, <<>>) of
                        {ok, AtomName} -> {ok, {t_custom, AtomName, lists:map(fun(E) -> {positional, E} end, Elements)}};
                        {error, nil} -> decode_error("CustomType", X)
                    end;
                _ -> decode_error("CustomType", X)
            end;
        _ -> decode_error("CustomType", X)
    end.

decode_error(Expected, Got) ->
    ExpectedString = list_to_binary(Expected),
    GotString = gleam_stdlib:classify_dynamic(Got),
    DecodeError = {decode_error, ExpectedString, GotString, []},
    {error, [DecodeError]}.

% This is copy pasted from gleam's stdlib and performs some additional checks to
% make sure the given atom is a gleam's custom type atom. Stdlib doesn't export
% it so I had to copy it.
% It returns `{ok, CamelCaseAtomName}` in case it really is a valid Gleam atom
% name.
inspect_maybe_gleam_atom(<<>>, none, _) ->
    {error, nil};
inspect_maybe_gleam_atom(<<First, _Rest/binary>>, none, _) when ?is_digit_char(First) ->
    {error, nil};
inspect_maybe_gleam_atom(<<"_", _Rest/binary>>, none, _) ->
    {error, nil};
inspect_maybe_gleam_atom(<<"_">>, _PrevChar, _Acc) ->
    {error, nil};
inspect_maybe_gleam_atom(<<"_",  _Rest/binary>>, $_, _Acc) ->
    {error, nil};
inspect_maybe_gleam_atom(<<First, _Rest/binary>>, _PrevChar, _Acc)
    when not (?is_lowercase_char(First) orelse ?is_underscore_char(First) orelse ?is_digit_char(First)) ->
    {error, nil};
inspect_maybe_gleam_atom(<<First, Rest/binary>>, none, Acc) ->
    inspect_maybe_gleam_atom(Rest, First, <<Acc/binary, (uppercase(First))>>);
inspect_maybe_gleam_atom(<<"_", Rest/binary>>, _PrevChar, Acc) ->
    inspect_maybe_gleam_atom(Rest, $_, Acc);
inspect_maybe_gleam_atom(<<First, Rest/binary>>, $_, Acc) ->
    inspect_maybe_gleam_atom(Rest, First, <<Acc/binary, (uppercase(First))>>);
inspect_maybe_gleam_atom(<<First, Rest/binary>>, _PrevChar, Acc) ->
    inspect_maybe_gleam_atom(Rest, First, <<Acc/binary, First>>);
inspect_maybe_gleam_atom(<<>>, _PrevChar, Acc) ->
    {ok, Acc};
inspect_maybe_gleam_atom(_, _, _) ->
    {error, nil}.

uppercase(X) -> X - 32.
