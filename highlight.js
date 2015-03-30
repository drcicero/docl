
function highlight(string) {
    "use strict";

    var inserts = {};
    var i = 0;

    var wrapclass = function(klass) { return function (_, x, y) {
        inserts[i] = "<span class=" + klass + ">" + x + "</span>";
        console.log(x, y);
        return "$" + i++ + ";" + y;
    }};

    var suspend = function(x) {
        inserts[i] = ""+x;
        return "$" + i++ + ";";
    };

    return (string .replace(/&/g, "&amp;") .replace(/</g, "&lt;") + "<br>")

        .replace(/\n/g, "<br>")
        .replace(/\t/g, "    ")
        .replace(/ /g, "<wbr>&nbsp;")

        .replace(/\$/g, suspend)

        .replace(/(\\\\)()/g, wrapclass("escape"))
        .replace(/(\\["'])()/g, wrapclass("escape"))

        .replace(/('.+?')()/g, wrapclass("string"))
        .replace(/(".+?")()/g, wrapclass("string"))

        .replace(/(--.+?)(<br>)/g, wrapclass("comment"))

        /*.replace(/(d+)([^;])/g, wrapclass("number"))*/
        .replace(/([=()#[\]+*\-{}])()/g, wrapclass("operator"))

        .replace(/(elseif|do|in|if|for|end|else|then|break|until|local|while|return|function)(<)/g, wrapclass("keyword"))

        .replace(/\$.+?;/g, function(x) {return inserts[parseInt(x.slice(1,-1))];})
        .replace(/\$.+?;/g, function(x) {return inserts[parseInt(x.slice(1,-1))];})
        .replace(/\$.+?;/g, function(x) {return inserts[parseInt(x.slice(1,-1))];})

        .slice(0, -4);
}

function find_code () {
    "use strict";
    var codes = document.getElementsByClassName("language-lua");
    for (var i=0; i<codes.length; i++) {
      codes[i].innerHTML = highlight(codes[i].innerHTML);
      codes[i].style.whiteSpace = "";
    }
}
find_code();
