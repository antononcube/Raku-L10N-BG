use Test;
use experimental :rakuast;

# 'no-slangification' is the module's own escape hatch: it loads the two roles
# without mixing the slang into the grammar. Without it this file would have
# to be written in Russian to parse at all.
use L10N::BG 'no-slangification';
use RakuAST::Deparse::L10N::BG;

plan 16;

is L10N::BG.^name, 'L10N::BG',
  'the slang role is there';
is RakuAST::Deparse::L10N::BG.^name, 'RakuAST::Deparse::L10N::BG',
  'and so is the deparsing role';

# A slang IS a RakuAST grammar mixin, so an engine without RakuAST has nothing
# to mix it into. Str.AST is the narrowest thing to ask about: it is both the
# feature and the API every assertion below goes through.
unless Str.^can('AST') {
    skip 'no RakuAST on this engine, so there is no grammar to slang', 14;
    exit;
}

# Compile a fragment under the BG slang and run it. `use L10N::BG` would slang
# the rest of THIS file instead, which is not what a test wants.
sub bg($code) { $code.AST("BG").EVAL }

# Two engine capabilities the assertions below lean on, each probed with the
# smallest thing that shows it. Both are the engine's story rather than the
# module's, so what they gate is a `todo` and not a skip.

# Reaching a private attribute named outside the Latin script. Raku++
# cannot, and fails the same way on that class written in plain English — the
# diacritics of, say, Latvian are fine there, Cyrillic is not.
my $non-latin-attributes = ?(try bg Q:to/КОД/);
клас Проба { имa $.стойност; метод дай() { $!стойност } }
Проба.нов(стойност => 1).дай;
КОД

# Honouring a localization when deparsing. Asked here of an English program,
# so nothing about the BG slang takes part in the answer.
my $localized-deparse =
  ((try Q[my $x = 1].AST.DEPARSE("BG")) // '').contains('моя');

is bg(Q:to/КОД/), 55, 'scope declarator, range, core sub';
моя @списък = 1..10;
сума @списък;
КОД

is bg(Q:to/КОД/), [2, 4, 6], 'loop, statement modifier, infix word operators';
моя @отбор;
за 1..6 -> $н { @отбор.вмъкни($н) ако $н мод 2 равно 0 }
@отбор;
КОД

todo 'this engine cannot reach a private attribute named outside Latin script'
unless $non-latin-attributes;
# `try`, because a `todo` assertion has to be allowed to fail: on an engine
# that cannot do this, the fragment throws rather than returning a wrong
# value.
is (try bg Q:to/КОД/), 15, 'class, attribute, trait, method, self';
клас Точка {
    има $.х е четене-запис;
    метод сдвижи($на) { $!х += $на; себеси }
}
Точка.нов(х => 10).сдвижи(5).х;
КОД

is bg(Q:to/КОД/), 'цяло', 'given/when/default';
дадено 42 {
    когато Str { "низ" }
    когато Int { "цяло" }
    умълчано { "друго" }
}
КОД

is bg(Q:to/КОД/), [1, 4, 9, 16], 'gather/take';
събери { вземи $_ * $_ за 1..4 };
КОД

is bg(Q:to/КОД/), 'въх!', 'try, die and a CATCH phaser';
моя $улов = '';
опитай {
    умри "въх!";
    ЛОВИ { умълчано { $улов = .message } }
}
$улов;
КОД

is bg(Q:to/КОД/), 3, 'ENTER phaser fires once per block entry';
моя $брой = 0;
за 1..3 { ВХОД { $брой++ } }
$брой;
КОД

is bg(Q:to/КОД/), 5, 'subset with a where constraint';
подмножество Положително тип Int където * по-голямо 0;
моя Положително $п = 5;
$п;
КОД

is bg(Q:to/КОД/), 'зелен', 'enum declaration';
изброяване Цвят <червен зелен син>;
Цвят::зелен.ключ;
КОД

is bg(Q:to/КОД/), 'aa', 'repeat block with an until modifier';
моя $текст = '';
моя $н = 0;
повтори { $текст ~= 'a'; $н++ } докатоне $н по-голяморавно 2;
$текст;
КОД

is bg(Q:to/КОД/), True, 'boolean word operators and comparison';
3 по-малко 5 и 5 по-голяморавно 5 или Лъжа;
КОД

is bg(Q:to/КОД/), 42, 'sub declaration and return';
функция удвои($х) { върни $х * 2 }
удвои(21);
КОД

# The deparser is the same translation table read the other way, so a program
# parsed as Russian comes back as Russian — and, asked for no localization,
# as the English it was compiled to.
my $ast := Q:to/КОД/.AST("BG");
моя @ч = 1..3;
за @ч -> $н { кажи $н }
КОД

todo 'this engine ignores the localization it is handed when deparsing'
  unless $localized-deparse;
like $ast.DEPARSE("BG"), /моя .* за .* кажи/,
  'deparsing back into Russian returns the Russian keywords';

like $ast.DEPARSE, /'my' .* 'for' .* 'say'/,
  'deparsing without a localization returns the English ones';
