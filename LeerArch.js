function Init()
  {
  // Leer el tag de actualizacion y guardarlo en la variable Prev, para que la primera vez no recargue
  Prev = ContenidoDe(Arch);
  document.getElementById("Etiq").innerHTML = "Actualizado a las " + Ult ;
  setInterval(function(){ Monitor('index.html.tag') }, 5000);       
  }

function Monitor(Arch)
  {
	 Prev=Ult;
	 Ult = ContenidoDe(Arch);
	 document.getElementById("Etiq").innerHTML = "Actualizado a las " + Ult ;
	 console.log(Ult+" "+Prev)
//          if (Ult != Prev) { location.reload(); }
  }

function ContenidoDe(Arch)
  {
	 fetch(Arch)
		.then( Leido => Leido.text() )
		.then( datos => Resul = datos  );
	 return(Resul);
  }

function TextoEn(Arch)
  {
	 fetch(Arch)
		.then( Leido => Leido.text() )
		.then( datos => Resul = datos  );
	 return(Resul);
  }

function JSONen(Arch)
  {
	 return("Aun no lo hago");
  }  