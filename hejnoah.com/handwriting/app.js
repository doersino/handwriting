(function () {

var pagewidth = Math.min(document.documentElement.clientWidth, 500);

var strokescale = function(s) {
    var pointscale = d3.scaleQuantize()
        .domain([0, pagewidth])
        .range(Array.from(Array(200).keys()));

    for (var i = s.length - 1; i >= 0; i--) {
        s[i] = {x:pointscale(s[i]['x']), y:pointscale(s[i]['y'])};
    }
    return s;
};

var printstroke = function(s) {
    dump = d3.select("#info")
    dump.style("display", "none");

    dump = d3.select("#dump")
    dump.style("display", "block");
    dump.selectAll("span").remove();
    dump.append("span").attr("class", "dump").text(s);
};

var performquery = function(s) {
    query = d3.select("#query");
    query.style("display", "block");

    var i = 0;
    var load = ["/", "-", "\\", "|"];
    var loader = setInterval(function() {
        query.selectAll("span").remove();  // TODO make more effiecient or just get rid of this
        query.append("span").attr("class", "query").text(load[i]);
        i++;
    }, 50);

    var xmlhttp = new XMLHttpRequest();

    xmlhttp.onreadystatechange = function() {
        if (xmlhttp.readyState == 4 && xmlhttp.status == 200) {
            query = d3.select("#query");
            query.selectAll("span").remove();
            query.append("span").attr("class", "query").text(xmlhttp.responseText);
            clearInterval(loader);

            // TODO draw characteristics into d3 graph? might be tricky because of scaling
        }
    }

    xmlhttp.open("POST", "test.py", true);
    xmlhttp.setRequestHeader("Content-type","application/x-www-form-urlencoded");
    xmlhttp.send("pen=" + s);
};

var stroke = [];
var tablet = d3.select("#tablet");

var canvas = tablet.append("svg")
    .attr("width", pagewidth)
    .attr("height", pagewidth)
    .on("mousedown", mousedown)
    .on("mouseup", mouseup)
    .on("touchstart", touchstart)
    .on("touchend", touchend)

function mousedown() {
    var m = d3.mouse(this);
    var p = {x:Math.trunc(m[0]), y:Math.trunc(m[1])};

    // clear canvas when stroke begins
    canvas.selectAll("*").remove();

    // draw first stroke point on canvas
    canvas.append("circle").attr("cx", p.x).attr("cy", p.y);
    stroke.push(p);

    canvas.on("mousemove", mousemove);
}

// TODO remove redundancy
function mousemove() {
    var m = d3.mouse(this);
    var p = {x:Math.trunc(m[0]), y:Math.trunc(m[1])};

    // draw next stroke point on canvas
    canvas.append("circle").attr("cx", p.x).attr("cy", p.y);
    stroke.push(p);
}

function mouseup() {
    // dump recorded stroke
    output = JSON.stringify(strokescale(stroke), null, 2);
    printstroke(output);
    performquery(output);

    // restart for new stroke
    stroke = [];
    canvas.on("mousemove", null);
}

function touchstart() {
    var m = d3.touches(this)[0];
    var p = {x:Math.trunc(m[0]), y:Math.trunc(m[1])};

    // clear canvas when stroke begins
    canvas.selectAll("*").remove();

    // draw first stroke point on canvas
    canvas.append("circle").attr("cx", p.x).attr("cy", p.y);
    stroke.push(p);

    canvas.on("touchmove", touchmove);
}

function touchmove() {
    var m = d3.touches(this)[0];
    var p = {x:Math.trunc(m[0]), y:Math.trunc(m[1])};

    // draw next stroke point on canvas
    canvas.append("circle").attr("cx", p.x).attr("cy", p.y);
    stroke.push(p);
}

function touchend() {
    // dump recorded stroke
    output = JSON.stringify(strokescale(stroke), null, 2);
    printstroke(output);
    performquery(output);

    // restart for new stroke
    stroke = [];
    canvas.on("touchmove", null);
}

})();

