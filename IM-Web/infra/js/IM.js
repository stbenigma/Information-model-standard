// GLOBAL VARIABLES

var svgList;
var gList;
var boxList = [];
var recsList = [];
var titleList = [];
var attributesList = [];
var labelsList = [];
var linesList = [];
var recDimensions = [];
var recRelations = [];
var tolerance = 2;



// RUN

window.onload  = function(){
	svgList = document.getElementsByTagName("svg");
	gList = document.getElementsByTagName("g");
	sorting();
	addIdsToSVGs();
	addIdsToRecs();
	addIdsToLines();
	getRecDimensions();
	cleanUpAttributes();
	styleRecs();
	styleTitles();
	styleAttributes();
	styleLabels();
	establishRelations();
	addMouseEventsToElements();
};




// -------------------------------------------------------------------------------------------------------------------------------------
//  1. DATA
// -------------------------------------------------------------------------------------------------------------------------------------

// ---------------------------------------------------
// 1.1 SORT DATA INTO LISTS
// ---------------------------------------------------

function sorting(){
	let isEntity = false;
	for (let i = 0; i < gList.length; i++){
		isEntity = false;
		if (gList[i].children[0].tagName == "text"){
			labelsList.push(gList[i]);
		} else if (gList[i].children[0].tagName == "path"){
			linesList.push(gList[i]);
		}
		for (let j = 0; j < gList[i].children.length; j++){
			if (gList[i].children[j].href != null) {
				isEntity = true;
				titleList.push(gList[i].children[j].children[0]);
			}
		}
		if (isEntity){
			boxList.push(gList[i]);
			recsList.push(gList[i].children[0]);
		}
	}
	
	for (let i = 0; i < boxList.length; i++){
		for (let j = 0; j < boxList[i].children.length; j++){
			if (boxList[i].children[j].tagName == "text"){
				attributesList.push(boxList[i].children[j]);
			}
		}
	}
}

function cleanUpAttributes(){
	for (let i = 0; i < recsList.length; i++){
		for (let j = recsList[i].parentNode.children.length - 1; j >= 0; j--){
			if (recsList[i].parentNode.children[j].tagName === "text"){
				let attribute = recsList[i].parentNode.children[j];

				let translate = pathValues(recsList[i].parentNode.getattribute("transform"));
				for (k in translate) translate[k] = parseInt(translate[k]);
				let x = parseInt(attribute.getattribute("x"));
				let y = parseInt(attribute.getattribute("y"));
				let id = pathValues(attribute.parentNode.parentNode.id);
		
				x += translate[0];
				y += translate[1];

				if (pathValues(recsList[i].id)[0] === id[0]){
					if (!checkWithinBox(x,y,recDimensions[i].x, recDimensions[i].y, recDimensions[i].w, recDimensions[i].h)){
						recsList[i].parentNode.removeChild(attribute);
					}
				}
			}
		}
	}
}

// --------------------------------------
// 1.2 INDEXING FUNCTIONS
// --------------------------------------

function addIdsToSVGs(){
	let h3 = [];
	h3 = document.getElementsByTagName("h3");
	let index = 0;
	for (let i = 0; i < h3.length; i++){
		if (/^DIAG[0-9]+/g.test(h3[i].id)){
			svgList[index].id = "SVG" + h3[i].id.match(/[0-9]+/g)[0];
			index++;
		}
	}
}

function addIdsToRecs(){
	for (i in recsList){
		recsList[i].id = "DIAG" + recsList[i].parentNode.parentNode.id.match(/[0-9]+/g)[0] + "-REC" + i.toString();
	}
}

function addIdsToLines(){
	for (i in linesList){
		linesList[i].id = "DIAG" + linesList[i].parentNode.id.match(/[0-9]+/g)[0] + "-LINE" + i.toString();
	}
}


// -------------------------------------------
// 1.3 EXTRACT DATA
// -------------------------------------------

function getRecDimensions(){
	for (let i = 0; i < recsList.length; i++){
		let t = colorValues(boxList[i].getattribute("transform"));
		let x = parseInt(t[0]);
		let y = parseInt(t[1]);
		let w = parseInt(recsList[i].getattribute("width"));
		let h = parseInt(recsList[i].getAttribute("height"));
		let dict = {"x":x, "y":y, "w":w, "h": h};
		recDimensions.push(dict);
	}
}

function establishRelations(){

	// (1.) LINES
	// read out lines connected to this rec
	let recID;
	let lineID;
	for (rec in recsList){
		let relations = {"lines":[], "recs":[]}
		recRelations.push(relations);
		recID = pathValues(recsList[rec].id);

		// cycle through all lines
		for (let line = 0; line < linesList.length; line++){
			lineID = pathValues(linesList[line].id);
			//exclude different diagrams
			if (recID[0] === lineID[0]){
				// select the first and the last line segment
				let start = linesList[line].children[0];
				let end = linesList[line].children[linesList[line].children.length - 1];
				start = start.getAttribute("d");
				let endD = end.getAttribute("d");
				// make sure, that last segment isn't crow's foot
				if (!checkIfRelative(endD)) {
					end = linesList[line].children[linesList[line].children.length - 2];
					endD = end.getAttribute("d");
				}
				//set up data to be checked
				start = pathValues(start);
				end = pathValues(endD);
				let x0 = start[0];
				let y0 = start[1];
				let x1 = end[2];
				let y1 = end[3];
				let x = recDimensions[rec].x;
				let y = recDimensions[rec].y;
				let w = recDimensions[rec].w;
				let h = recDimensions[rec].h;
	
				// cycle through boxes around rec
				// top, left, bottom, right
				let rel = false;
				for (let i = 0; i < 4; i++){
					let p, q;
					if (i < 3){
						p = x - tolerance;
					} else {
						p = x + w;
					}
					if (i === 2){
						q = y + h;
					} else {
						q = y - tolerance;
					}
					let l, k;
					if (i % 2 === 0){
						l = w;
						k = tolerance;
					} else {
						l = tolerance;
						k = h;
					}
	
					for (let j = 0; j < 2; j++){
						let a, b;
						if (j % 2 === 0){
							a = x0;
							b = y0;
						} else {
							a = x1;
							b = y1;
						}
						// check if point lies within this tolerance box adjacent to rec
						if (checkWithinBox(a,b,p,q,l,k)) rel = true;
					}
				}
				// if the point lies within one of the four boxes adjacent to rec, it is related
				if (rel) relations.lines.push(linesList[line]);
			}
		}
	}

	// (2.) RECS
	// read out recs connected to this rec

	let rel = false;
	for (let i = 0; i < recsList.length; i++){
		let rec1 = recsList[i];
		for (let j = 0; j < recsList.length; j++){
			let rel = false;
			let rec2 = recsList[j];
			if (i !== j){
				for (let l = 0; l < recRelations[i].lines.length; l++){
					let line1 = recRelations[i].lines[l];
					for (let m = 0; m < recRelations[j].lines.length; m++){
						let line2 = recRelations[j].lines[m];
						if (line1.id === line2.id){
							rel = true;
						}
					}
				}
			}
			if (rel){
				recRelations[i].recs.push(rec2);
			}
		}
	}
}


// -------------------------------------------------------------------------------------------------------------------------------------
//  2. INTERACTION
// -------------------------------------------------------------------------------------------------------------------------------------

// ------------------------------------------------------------
// 2.1 INTERACTIVE FUNCTINOS
// ____________________________________________________________

function mouseover(elem){
	// elem must be a rect
	// in case mouse event is triggered by a title or attribute, find corr. rec
	if (elem.tagName === "text" || elem.tagName === "a"){
		let rec;
		for (let i = 0; i < elem.parentNode.parentNode.children.length; i++){
			if (elem.parentNode.parentNode.children[i].tagName === "rect"){
				rec = elem.parentNode.parentNode.children[i];
			}
		}
		elem = rec;
	}
	elem.style.filter = 'url(#dropshadow)';
	let id = pathValues(elem.id)[1];
	let lines = recRelations[id].lines;
	let recs = recRelations[id].recs;

	// (1.A) RELATED LINES
	for (j in lines){
		for (let l = 0; l < lines[j].children.length; l++){
			setLineThickness(lines[j], "1.5px");
		}
	}
	
	// (1.B) LINES INVERSE SELECTION
	for (j in linesList){
		let otherIndeces = pathValues(linesList[j].id);
		let recIndeces = pathValues(elem.id);
		let rel = false;
		// exclude lines in different diagram
		if (recIndeces[0] !== otherIndeces[0]){
			rel = true;
		} else {
			for (let l = 0; l < lines.length; l++){
				let thisIndeces = pathValues(lines[l].id);
				// exclude related lines
				if (otherIndeces[1] === thisIndeces[1]){
					rel = true;
				}
			}
		}
		if (!rel){
			setLineColor(linesList[j], "#dddddd");
			setLineThickness(linesList[j], "1px");
		}
	}	
	
	// (2.A) RELATED RECS
	for (j in recs){
		// styling
	}	
	
	// (2.B) RECS INVERSE SELECTION
	for (j in recsList){
		let otherIndeces = pathValues(recsList[j].id);
		let recIndeces = pathValues(elem.id);
		let rel = true;
		//exclude this rec
		if (recsList[j].id === elem.id){
			rel = true;
		} else {
			rel = false;
			// exclude recs in different diagrams
			if (recIndeces[0] !== otherIndeces[0]){
				rel = true;
			} else {
				// exclude related recs
				for (let l = 0; l < recs.length; l++){
					let thisIndeces = pathValues(recs[l].id);
					if (otherIndeces[1] === thisIndeces[1]){
						rel = true;
					}
				}
			}
			if (!rel){
				fadeOutRec(recsList[j]);
				let children = recsList[j].parentNode.children;
	// (3.) TEXT
				for (let k = 0; k < children.length; k++){
					if (children[k].tagName === "a" || children[k].tagName === "text") children[k].style.opacity = "0.3";
				}
			}
		}
	}
}

function mouseout(elem){
	// elem must be a rec
	// in case mouse event is triggered by a title or attribute, find corr. rec

	let p;
	if (elem.tagName === "text"){
		// default: elem is an attribute
		p =  elem.parentNode;
		// check if elem is a title
		if (/^DIAG[0-9]+-ENTI[0-9]+/.test(elem.id)){
			p = elem.parentNode.parentNode;
		}
		let rec;
		for (let i = 0; i < p.children.length; i++){
			if (p.children[i].tagName === "rect"){
				rec = p.children[i];
			}
		}
		elem = rec;
	}
	// elem is now a rec

	elem.style.filter = "";
	let id = pathValues(elem.id)[1];
	let lines = recRelations[id].lines;
	let recs = recRelations[id].recs

	// (1.A) RELATED LINES
	for (j in lines){
		for (let l = 0; l < lines[j].children.length; l++){
			setLineThickness(lines[j], "1px");
		}
	}
	
	// (1.B) LINES INVERSE SELECTION
	// cycle through all lines for simplicity's sake
	for (j in linesList){
		setLineColor(linesList[j], "black");
		setLineThickness(linesList[j], "1px");
	}

	// (2.A) RECS

	// (2.B) RECS INVERSE SELECTION
	// cycle through all recs for simplicty's sake
	for (j in recsList){
		recsList[j].style.fill = "";
		recsList[j].style.stroke = "";
		let children = recsList[j].parentNode.children;
	// (3.) TEXT
		for (let k = 0; k < children.length; k++){
			if (children[k].tagName === "a" || children[k].tagName === "text") children[k].style.opacity = "1";
		}
	}
}


// ------------------------------------------------------------
// 2.2 ASSIGNMENT
// ____________________________________________________________

function addMouseEventsToElements(){
	for (i in recsList){
		recsList[i].addEventListener("mouseover", function(e){
			mouseover(e.target);
		});

		recsList[i].addEventListener("mouseleave", function(e){
			mouseout(e.target);
		});
	}

	for (i in titleList) {
		titleList[i].addEventListener("mouseover", function(e){
			mouseover(e.target);
		});

		titleList[i].addEventListener("mouseleave", function(e){
			mouseout(e.target);
		});
	}

	for (i in attributesList) {
		attributesList[i].addEventListener("mouseover", function(e){
			mouseover(e.target);
		});

		attributesList[i].addEventListener("mouseleave", function(e){
			mouseout(e.target);
		});
	}
}


// -------------------------------------------------------------------------------------------------------------------------------------
//  3. STYLING
// -------------------------------------------------------------------------------------------------------------------------------------

// ------------------------------------------------------------
// 3.1 STATIC
// ____________________________________________________________

function styleRecs(){
	for (let i = 0; i < boxList.length; i++){
		let r = boxList[i].children[0];
		styleStrokes(boxList[i]);
		r.classList.add("box");
	}
}

function styleStrokes(rec){
	let cs = rec.getAttribute("fill");
	let cv = colorValues(cs);
	let strokeCV = createStrokeColor(cv);
	let strokeCS = colorString(strokeCV);
	rec.style.stroke = strokeCS;
}

function styleTitles(){
	for (let i = 0; i < titleList.length; i++){
		titleList[i].setAttribute("style", "font-size:10px; fill:black; Color:black; z-index:100;");
		// x an y attributes have to be treated seperately fsr can't override 🤷‍♀️
		titleList[i].setAttribute("x", "10px");
		titleList[i].setAttribute("y", "16px");
		titleList[i].classList.add("entity-text");
	}
}

function styleAttributes(){
	for (let i = 0; i < attributesList.length; i++){
		attributesList[i].setAttribute("style", "font-size:10px; fill:black; font-weight:400;");
			attributesList[i].classList.add("entity-text");
	}
}

function styleLabels(){
	for (let i = 0; i < labelsList.length; i++){
		labelsList[i].setAttribute("style", "font-size:5px; fill:black; font-weight:normal; font-style:italic;")
	}
}


// ------------------------------------------------------------
// 3.2 UPON INTERACTION
// ____________________________________________________________


function setLineColor(line, color){
	for (let l = 0; l < line.children.length; l++){
		line.children[l].setAttribute("stroke", color);
	}
}

function setLineThickness(line, t){
	for (let l = 0; l < line.children.length; l++){
		line.children[l].setAttribute("stroke-width", t);
	}
}

function fadeOutRec(rec){
	let fill = rec.parentNode.getAttribute("fill");
	let stroke = rec.parentNode.style.stroke;
	fill = colorValues(fill);
	stroke = colorValues(stroke);
	fill = desaturate(fill, 0.7);
	stroke = desaturate(stroke, 0.7);
	fill = brighten(fill, 15);
	stroke = brighten(stroke, 15);
	rec.style.fill = colorString(fill);
	rec.style.stroke =  colorString(stroke);
}


// -------------------------------------------------------------------------------------------------------------------------------------
//  4. UTILS
// -------------------------------------------------------------------------------------------------------------------------------------

// ------------------------------------------------------------
// 4.1 COMPUTE
// ____________________________________________________________

function pathValues(d){
	return d.match(/[0-9\.]+/g);
}

function checkIfRelative(d){
	return /(L)/g.test(d);
}

function checkWithinBox(a,b,p,q,l,k){
	let extra = 2;
	return (a > p - extra && a < p + l + extra) && (b > q - extra && b < q + k + extra);
}

function desaturate(color, s){
	for (c in color) color[c] /= 255;
	let i = color[0] * 0.3 + color[1] * 0.59 + color[2] * 0.11;
	let greyscale = [i,i,i];
  let d = [];
	for (c in greyscale) d[c] = greyscale[c];
	for (c in greyscale) greyscale[c] *= 255;
	for (c in d) d[c] -= color[c];
	for (c in d) d[c] *= s;
	for (c in color) color[c] += d[c];
	for (c in color) color[c] *= 255;
	return color;
}

function brighten(color, b){
	for (c in color) color[c] += b;
	return color;
}

function colorValues(cs){
	var rgb = cs;
	rgb = rgb.replace(/[^\d,]/g, '').split(',');
	for (let i = 0; i < 3; i++) rgb[i] = parseInt(rgb[i]);
	return rgb;
}

function colorString(cv){
	var rgb = "rgb(" + cv[0] + "," + cv[1] + "," + cv[2] + ")";
	return rgb;
}

function createStrokeColor(color){
	for (let i = 0; i < color.length; i++){
		color[i] -= 40;
	}
	return color;
}


// ------------------------------------------
// 4.2 PRINT
// ------------------------------------------

function printElem(elem){
		var newWindow = window.open();
		var btncontainer = elem.parentNode;
		btncontainer.removeChild(elem);
		var content = btncontainer.parentNode;

		newWindow.document.write(content.innerHTML);

		attachCSS("css/main.css", newWindow.document.head);

		var logo = newWindow.document.createElement('h1');
		logo.innerHTML = "foryouandyourcustomers";
		logo.classList.add("logo-text");

		newWindow.document.body.append(logo);

		newWindow.print();

		btncontainer.append(elem);
}

function attachCSS(url, parent){
		var link = document.createElement('link');

		link.rel = 'stylesheet';  
    link.type = 'text/css'; 
    link.href = url; 

    parent.append(link);
}




