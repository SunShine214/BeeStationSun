import { useState } from 'react';
import { Button, DraggableClickableControl } from 'tgui/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type OrbitalData = {
  current_altitude: number;
  station_pos: number[];
  orbital_velocity: number[];
  semi_major_axis: number;
  eccentricity: number;
  arg_of_periapsis: number;
  station_target_angle: number;
  station_actual_angle: number;
  orbital_angle: number;
  orbital_items: OrbitalItem[];
  cinus_radius: number;
  cinus_name: string;
};

type OrbitalItem = {
  name: string;
  radius: number;
  pos_x: number;
  pos_y: number;
}

export const OrbitalHeightControl = () => {
  return (
    <Window width={640} height={580}>
      <Window.Content
        style={{
          fontFamily: 'Consolas, "Courier New", monospace',
          background: 'linear-gradient(180deg, #0a0a0a 0%, #1a1a1a 100%)',
        }}
      >
        <OrbitalHeightContent />
      </Window.Content>
    </Window>
  );
};

const OrbitalRing = (props) => {
  const { center_x, center_y, semi_major_axis, eccentricity, arg_of_periapsis, color, pixel_scale } = props;
  const display_x = center_x * pixel_scale;
  const display_y = center_y * pixel_scale;
  const display_sma = semi_major_axis * pixel_scale;
  if(semi_major_axis <= 0 || eccentricity < 0 || eccentricity >= 1) return null;
  return (
      <ellipse cx={-(display_sma * eccentricity)} cy={0} rx={display_sma} ry={display_sma * Math.sqrt(1 - eccentricity * eccentricity)} fill="none" stroke={color} transform={`translate(${display_x} ${display_y}) rotate(${arg_of_periapsis})`} />
  );
};

const OrbitalHeightContent = () => {
  const { act, data } = useBackend<OrbitalData>();
  const {
    station_pos = [0, 0],
    current_altitude = 0,
    orbital_velocity = [0, 0],
    semi_major_axis = 0,
    eccentricity = 0,
    arg_of_periapsis = 0,
    station_target_angle = 0,
    station_actual_angle = 0,
    orbital_angle,
    cinus_radius,
  } = data;
  const pixel_scale = 1 / 40000;
  const [target_x, set_target_x] = useState(Math.cos(station_target_angle));
  const [target_y, set_target_y] = useState(Math.sin(station_target_angle));
  return (
    <>
    <DraggableClickableControl
        value={target_x}
        dragMatrix={[-1, 0]}
        step={1}
        stepPixelSize={1}
        onDrag={(e, value) => {
          set_target_x(value);
        }}
        onClick={(e, value) => {}}
        updateRate={5}
      >
        {(control_x) => (
          <DraggableClickableControl
            value={target_y}
            dragMatrix={[0, -1]}
            step={1}
            stepPixelSize={1}
            onDrag={(e, value) => {
              set_target_y(value);
              act('adjust_angle', { 'angle': Math.atan2(target_y, target_x) * 180 / Math.PI });
            }}
            onClick={(e, value) => {}}
            updateRate={5}

           >
            {(control_y) => (
              <svg
              onMouseDown={(e) => {
              control_x.handleDragStart(e);
              control_y.handleDragStart(e);
              }}
            viewBox="-25 -25 50 50"
            height="100px"
            width="100px">
              <line x1={0} y1={0} x2={0} y2={25} transform={`rotate(${station_target_angle} 0 0)`} stroke="blue" />
              </svg>
            )}
          </DraggableClickableControl>
        )}
    </DraggableClickableControl>
    <Button
        mt="-10px"
        content={'orbit keeping'}
        onClick={() => act('toggle_orbit_keeping')}
      />
    <Button
        mt="-10px"
        content={'increase'}
        onClick={() => act('increase_thrust')}
      />
    <Button
        mt="-10px"
        content={'decrease'}
        onClick={() => act('decrease_thrust')}
      />
    Height {Math.sqrt(station_pos[0]**2 + station_pos[1]**2) / 1000}
    <svg height="300px" width="300px" viewBox="-150 -150 300 300">
      <g transform="scale(1, -1)">
        <line x1={station_pos[0] * pixel_scale} y1={station_pos[1] * pixel_scale} x2={station_pos[0] * pixel_scale + 25} y2={station_pos[1] * pixel_scale} transform={`rotate(${station_actual_angle + orbital_angle} ${station_pos[0] * pixel_scale} ${station_pos[1] * pixel_scale})`} stroke="red" />
        <line x1={station_pos[0] * pixel_scale} y1={station_pos[1] * pixel_scale} x2={station_pos[0] * pixel_scale + 25} y2={station_pos[1] * pixel_scale} transform={`rotate(${station_target_angle + orbital_angle} ${station_pos[0] * pixel_scale} ${station_pos[1] * pixel_scale})`} stroke="blue" />
        <OrbitalRing center_x={0} center_y={0} semi_major_axis={semi_major_axis} eccentricity={eccentricity} arg_of_periapsis={arg_of_periapsis} color="#ffffff" pixel_scale={pixel_scale} />
        <circle cx={0} cy={0} r={cinus_radius * pixel_scale} fill="#e93c3c" />
        <rect x={station_pos[0] * pixel_scale - 2} y={station_pos[1] * pixel_scale - 2} width={4} height={4} fill="grey" />
      </g>
    </svg>
    </>
  );
};
