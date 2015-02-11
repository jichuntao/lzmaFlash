package
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.net.FileReference;
	import flash.utils.ByteArray;
	import flash.utils.getDefinitionByName;
	
	public class lzmaFlash extends Sprite
	{
		private var fs:FileReference;
		
		public function lzmaFlash()
		{
			fs = new FileReference();
			fs.addEventListener(Event.COMPLETE,onFsLoadOverFun);
			fs.addEventListener(Event.SELECT,onSelectFun);
			this.stage.addEventListener(MouseEvent.CLICK,onOpenFun);
		}
		
		private function onSelectFun(e:Event):void
		{
			fs.load();
		}
		private function onOpenFun(e:Event):void
		{
			fs.browse();
		}
		private function onFsLoadOverFun(e:Event):void
		{
			var byteArr:ByteArray=fs.data;
			var compression:String='';
			var zwsData:ByteArray;
			var swfSize:Number=0;
			var fileName:String = fs.name;
			//FWS CWS ZWS
			if(byteArr[1]!=0x57 || byteArr[2]!=0x53 ){
				trace('File is not swf');
				return;
			}
			
			if(byteArr[0]=='F'.charCodeAt(0)){
				compression='no';
			}
			else if(byteArr[0]=='C'.charCodeAt(0)){
				compression='zlib';
			}
			else if(byteArr[0]=='F'.charCodeAt(0)){
				compression='lzma';
			}
			else{
				trace('File is not swf');
				return;
			}
			swfSize=byteArr[4] | byteArr[5]<<8 | byteArr[6]<<16 | byteArr[7]<<24;
			
			trace('Signature: '+String.fromCharCode(byteArr[0])+'WS');
			trace('File Size: '+byteArr.length+' bytes');
			trace('Compression: '+compression);
			trace('SWF Version: '+byteArr[3]);
			trace('SWF Size: '+swfSize+' bytes');
			
			if(compression == 'lzma'){
				trace('File already LZMA compressed');
				return;
			}
			
			zwsData=new ByteArray();
			zwsData.writeUTFBytes("ZWS");
			
			zwsData.writeByte(13);	//swfversion 13  player 11.0.0.0
			
			swfSize += 8;	//lzma eos 8 bytes
			
			zwsData[4] = swfSize;
			zwsData[5] = swfSize>>8;
			zwsData[6] = swfSize>>16;
			zwsData[7] = swfSize>>24;
			
			var swfBytes:ByteArray=new ByteArray();
			swfBytes.writeBytes(byteArr,8);
			if(compression == 'zlib'){
				swfBytes.uncompress('zlib');
			}
			
			if(!checkLzmaLib()){
				trace('adobe player need to 11.4+');
				return;
			}
			swfBytes.compress('lzma');
			
			zwsData.position=12;
			zwsData.writeBytes(swfBytes,0,5);
			zwsData.writeBytes(swfBytes,13);
			
			var compressed_size:int=zwsData.length-17;
			zwsData[8]=compressed_size;
			zwsData[9]=compressed_size>>8;
			zwsData[10]=compressed_size>>16;
			zwsData[11]=compressed_size>>24;
			
			trace('Compression Size: '+zwsData.length+' bytes');
			trace('Optimization: '+(Math.round(10000-((zwsData.length/byteArr.length)*10000))/100) +'%');
			
			var save:FileReference=new FileReference();
			fileName=fileName.replace('.swf','_z.swf');
			save.save(zwsData,fileName);
		}
		private function checkLzmaLib():Boolean
		{
			var ret:Boolean=false;
			try{
				var cls:Class=getDefinitionByName('flash.utils.CompressionAlgorithm') as Class;
				if(cls.hasOwnProperty('LZMA')){
					ret=true;
				}
			}
			catch(e){
				ret=false;
			}
			return ret;
		}
	}
}