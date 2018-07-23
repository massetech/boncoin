# defmodule Boncoin.Plural do
#   @behaviour Gettext.Plural
#
#   def nplurals("zg"), do: 3
#
#   def plural("zg", 0), do: 0
#   def plural("zg", 1), do: 1
#   def plural("zg", _), do: 2
#
#   # Fallback to Gettext.Plural
#   def nplurals(locale), do: Gettext.Plural.nplurals(locale)
#   def plural(locale, n), do: Gettext.Plural.plural(locale, n)
# end
#
# defmodule Boncoin.Gettext do
#   use Gettext, otp_app: :boncoin, plural_forms: Boncoin.Plural
# end
