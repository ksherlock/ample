

__all__ = ['to_plist']

from xml.sax.saxutils import escape
from base64 import b64encode
from datetime import date, datetime, timezone

_header = (
	'<?xml version="1.0" encoding="UTF-8"?>\n'
	'<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">\n'
	'<plist version="1.0">\n'
)
_trailer = '</plist>\n'

INDENT = "  "

def _bad(x, indent=0):
	raise ValueError("plist: bad type: {} ({})".format(type(x), x))



def _encode_array(x, akku, indent=""):

	indent2 = indent + INDENT
	
	akku.append(indent + "<array>\n")

	for v in x:
		_encoder.get(type(v), _bad)(v, akku, indent2)

	akku.append(indent + "</array>\n")


def _encode_dict(x, akku, indent=""):

	indent2 = indent + INDENT

	akku.append(indent + "<dict>\n")
	for k,v in x.items():
		# key must be string?
		if type(k) != str:
			raise ValueError("plist: dictionary key must be string: {}: {}".format(type(k), k))
		akku.append("{}<key>{}</key>\n".format(indent2, escape(k)))
		_encoder.get(type(v), _bad)(v, akku, indent2)

	akku.append(indent + "</dict>\n")


def _encode_bool(x, akku, indent=""):
	if x: akku.append(indent + "<true/>\n")
	else: akku.append(indent + "<false/>\n")

def _encode_integer(x, akku, indent=""):
	akku.append("{}<integer>{}</integer>\n".format(indent, x))

def _encode_real(x, akku, indent=""):
	akku.append("{}<real>{}</real>\n".format(indent, x))

def _encode_string(x, akku, indent=""):
	akku.append("{}<string>{}</string>\n".format(indent, escape(x)))


# data is YYYY-MM-DD T HH:MM:SS Z
def _encode_date(x, akku, indent=""):
	s = x.strftime('%Y-%m-%d')
	akku.append("{}<date>{}</date>\n".format(indent, s))

def _encode_datetime(x, akku, indent=""):
	# if not x.tzinfo
		# raise ValueError("plist: datetime must have tzinfo: {}".format(x))

	# if x.tzinfo.utcoffset(x) == None:
		# raise ValueError("plist: datetime must have utc offset: {}".format(x))

	utc = x.astimezone(timezone.utc)
	s = utc.strftime('%Y-%m-%dT%H:%M:%SZ')
	akku.append("{}<date>{}</date>\n".format(indent, s))

def _encode_data(x, akku, indent=""):
	# data is base64 encoded

	CHUNKSIZE = 32
	if len(x) < CHUNKSIZE:
		akku.append("{}<data>{}</data>\n".format(indent, b64encode(x).encode('ascii')))
		return

	indent2 = indent + INDENT
	akku.append(indent + "<data>\n")

	for i in range(0, len(x), CHUNKSIZE):
		akku.append(
			"{}{}\n".format(
				indent2,
				b64encode(x[i:i+CHUNKSIZE]).encode('ascii')
			)
		)

	akku.append(indent + "</data>\n")

# data, data not yet supported.
_encoder = {
	str: _encode_string,
	float: _encode_real,
	int: _encode_integer,
	bool: _encode_bool,

	tuple: _encode_array,
	list: _encode_array,
	dict: _encode_dict,
	bytes: _encode_data,
	bytearray: _encode_data,
	date: _encode_date,
	datetime: _encode_datetime,
}

def to_plist(x):

	akku = []
	akku.append(_header)
	_encoder.get(type(x), _bad)(x, akku, INDENT)
	akku.append(_trailer)

	return ''.join(akku)


